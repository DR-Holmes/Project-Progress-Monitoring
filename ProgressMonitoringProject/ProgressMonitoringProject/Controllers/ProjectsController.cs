using ProgressMonitoringProject.Models;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/projects")]
    public class ProjectsController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet, Route("")]
        public IHttpActionResult GetAll()
        {
            var list = db.Projects.ToList();
            return Ok(list);
        }

        [HttpGet, Route("{id}")]
        public IHttpActionResult Get(int id)
        {
            var p = db.Projects.Find(id);
            if (p == null) return NotFound();
            return Ok(p);
        }

        [HttpPost, Route("")]
        public IHttpActionResult Create([FromBody] Project project)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            db.Projects.Add(project);
            db.SaveChanges();
            return Ok(project);
        }

        [HttpPut, Route("{id}")]
        public IHttpActionResult Update(int id, [FromBody] Project updated)
        {
            if (id != updated.id) return BadRequest("Id mismatch");
            db.Entry(updated).State = EntityState.Modified;
            db.SaveChanges();
            return Ok(updated);
        }

        [HttpDelete, Route("{id}")]
        public IHttpActionResult Delete(int id)
        {
            var p = db.Projects.Find(id);
            if (p == null) return NotFound();
            db.Projects.Remove(p);
            db.SaveChanges();
            return Ok();
        }

        [HttpGet]
        [Route("GetProjAssignData/{groupId}")]
        public IHttpActionResult GetProjectAssignmentData(int groupId, int currentSessionId)
        {
            var teamMembers = db.GroupMembers
                .Where(gm => gm.groupID == groupId)
                .Join(db.Students,
                      gm => gm.studentID,
                      s => s.regNum,
                      (gm, s) => new { GroupMember = gm, Student = s })
                .Join(db.Technologies,
                      x => x.Student.selectedTech,
                      t => t.id,
                      (x, t) => new TeamMemberDto
                      {
                          Name = x.Student.name,
                          RegNum = x.Student.regNum,
                          Technology = t.name,
                          CGPA = x.Student.currentCGPA
                      }).ToList();

            var currentAssignmentDetails = db.ProjectGroups
                .Where(pg => pg.id == groupId)
                .Join(db.OfferedProjects,
                      pg => pg.projectID,
                      op => op.id,
                      (pg, op) => new { pg, op })
                .Join(db.Projects,
                      x => x.op.projectID,
                      p => p.id,
                      (x, p) => new
                      {
                          ProjectId = p.id,
                          ProjectTitle = p.title,
                          ProjectRemarks = p.objectives
                      }).FirstOrDefault();

            var offeredProjects = db.OfferedProjects
                .Where(op => op.sessionID == currentSessionId)
                .Join(db.Projects,
                      op => op.projectID,
                      p => p.id,
                      (op, p) => new SelectableProjectDto
                      {
                          OfferedProjectId = op.id,
                          Title = p.title
                      }).ToList();

            return Ok(new AssignmentScreenDto
            {
                GroupId = groupId,
                TeamMembers = teamMembers,
                CurrentProject = currentAssignmentDetails?.ProjectTitle,
                PreviousRemarks = currentAssignmentDetails?.ProjectRemarks,
                SelectableProjects = offeredProjects
            });
        }

        [HttpPost]
        [Route("SaveProjectAssignment")]
        public IHttpActionResult SaveProjectAssignment(int groupId, int offeredProjectId, string supervisorId, string newRemarks)
        {
            var existingAssignment = db.AssignProjects
                .Where(ap => ap.studentGroupID == groupId)
                .FirstOrDefault();

            if (existingAssignment != null)
            {
                existingAssignment.offeredID = offeredProjectId;
                existingAssignment.supervisorID = supervisorId;
            }
            else
            {
                db.AssignProjects.Add(new AssignProject
                {
                    studentGroupID = groupId,
                    offeredID = offeredProjectId,
                    supervisorID = supervisorId
                });
            }

            var projectGroup = db.ProjectGroups
                .Where(pg => pg.id == groupId)
                .FirstOrDefault();

            if (projectGroup != null)
            {
                var project = db.OfferedProjects
                    .Where(op => op.id == offeredProjectId)
                    .Select(op => op.projectID)
                    .FirstOrDefault();

                projectGroup.projectID = offeredProjectId;
                projectGroup.supervisorID = supervisorId;

                if (project.HasValue)
                {
                    var projectToUpdate = db.Projects
                        .Where(p => p.id == project.Value)
                        .FirstOrDefault();

                    if (projectToUpdate != null)
                    {
                        projectToUpdate.objectives = newRemarks;
                    }
                }
            }

            db.SaveChanges();
            return Ok("Project Assigned");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }

    public class SelectableProjectDto
    {
        public int OfferedProjectId { get; set; }
        public string Title { get; set; }
    }

    public class TeamMemberDto
    {
        public string Name { get; set; }
        public string RegNum { get; set; }
        public string Technology { get; set; }
        public double? CGPA { get; set; }
    }

    public class AssignmentScreenDto
    {
        public int GroupId { get; set; }
        public List<TeamMemberDto> TeamMembers { get; set; }
        public string CurrentProject { get; set; }
        public string PreviousRemarks { get; set; } 
        public List<SelectableProjectDto> SelectableProjects { get; set; }
    }
}
