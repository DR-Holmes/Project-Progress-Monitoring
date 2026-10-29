//using ProgressMonitoringProject.Models;
//using System;
//using System.Collections.Generic;
//using System.Data.Entity;
//using System.Linq;
//using System.Threading.Tasks;
//using System.Web.Http;

//namespace ProgressMonitoringProject.Controllers
//{
//    [RoutePrefix("api/groups")]
//    public class ProjectGroupController : ApiController
//    {
//        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

//        [HttpGet, Route("")]
//        public async Task<IHttpActionResult> GetAll()
//        {
//            var list = await db.ProjectGroups.ToListAsync();
//            return Ok(list);
//        }

//        [HttpGet, Route("{id}")]
//        public async Task<IHttpActionResult> Get(int id)
//        {
//            var g = await db.ProjectGroups.FindAsync(id);
//            if (g == null) return NotFound();
//            return Ok(g);
//        }

//        [HttpPost, Route("")]
//        public async Task<IHttpActionResult> Create([FromBody] ProjectGroup group)
//        {
//            if (!ModelState.IsValid) return BadRequest(ModelState);
//            db.ProjectGroups.Add(group);
//            await db.SaveChangesAsync();
//            return Ok(group);
//        }

//        [HttpPut, Route("{id}")]
//        public async Task<IHttpActionResult> Update(int id, [FromBody] ProjectGroup updated)
//        {
//            if (id != updated.id) return BadRequest("id mismatch");
//            db.Entry(updated).State = EntityState.Modified;
//            await db.SaveChangesAsync();
//            return Ok(updated);
//        }

//        [HttpDelete, Route("{id}")]
//        public async Task<IHttpActionResult> Delete(int id)
//        {
//            var g = await db.ProjectGroups.FindAsync(id);
//            if (g == null) return NotFound();
//            db.ProjectGroups.Remove(g);
//            await db.SaveChangesAsync();
//            return Ok();
//        }

//        [HttpPost, Route("assign-offered")]
//        public async Task<IHttpActionResult> AssignOfferedProject([FromBody] AssignOfferedDto dto)
//        {
//            var group = await db.ProjectGroups.FindAsync(dto.GroupId);
//            if (group == null) return NotFound();

//            var op = await db.OfferedProjects.FindAsync(dto.OfferedProjectId);
//            if (op == null) return BadRequest("Offered project not found.");

//            var members = await db.GroupMembers.Where(gm => gm.groupID == group.id).ToListAsync();
//            foreach (var m in members)
//            {
//                var scores = await db.FYP1Score.Where(s => s.groupMemberID == m.id).ToListAsync();
//                if (scores.Any())
//                {
//                    var avg = scores.Average(s => s.score);
//                    if (avg < 50)
//                    {
//                        return BadRequest($"Member {m.studentID} has failing FYP-1 average ({avg}). Cannot allocate project.");
//                    }
//                }
//            }

//            group.projectID = dto.OfferedProjectId;
//            db.Entry(group).State = EntityState.Modified;
//            await db.SaveChangesAsync();

//            return Ok(new { message = "Offered project assigned to group", groupId = group.id });
//        }

       
//        [HttpPost, Route("promote-to-new-group")]
//        public async Task<IHttpActionResult> PromoteGroupToNewGroup([FromBody] PromoteGroupDto dto)
//        {
//            var src = await db.ProjectGroups.FindAsync(dto.GroupId);
//            if (src == null) return BadRequest("Source group not found.");

//            var members = await db.GroupMembers.Where(g => g.groupID == src.id).ToListAsync();
//            if (!members.Any()) return BadRequest("Source group has no members.");

//            foreach (var m in members)
//            {
//                var scores = await db.FYP1Score.Where(s => s.groupMemberID == m.id).ToListAsync();
//                if (!scores.Any()) return BadRequest($"Member {m.studentID} has no FYP-1 evaluation; cannot promote.");
//                var avg = scores.Average(s => s.score);
//                if (avg < 50) return BadRequest($"Member {m.studentID} failed FYP-1 (avg {avg}).");
//            }

//            var newGroup = new ProjectGroup
//            {
//                createdBy = dto.CreatedBy ?? src.createdBy,
//                supervisorID = dto.SupervisorId ?? src.supervisorID,
//                projectID = dto.OfferedProjectId
//            };
//            db.ProjectGroups.Add(newGroup);
//            await db.SaveChangesAsync();

//            foreach (var m in members)
//            {
//                db.GroupMembers.Add(new GroupMember
//                {
//                    groupID = newGroup.id,
//                    studentID = m.studentID,
//                    requestStatus = m.requestStatus
//                });
//            }

//            await db.SaveChangesAsync();
//            return Ok(new { newGroupId = newGroup.id });
//        }

        

//        protected override void Dispose(bool disposing)
//        {
//            if (disposing) db.Dispose();
//            base.Dispose(disposing);
//        }

//        public class AssignOfferedDto { public int GroupId { get; set; } public int OfferedProjectId { get; set; } }
//        public class PromoteGroupDto { public int GroupId { get; set; } public int OfferedProjectId { get; set; } public string CreatedBy { get; set; } public string SupervisorId { get; set; } }
//    }
//}
