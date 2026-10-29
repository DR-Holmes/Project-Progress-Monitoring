using ProgressMonitoringProject.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.UI.WebControls;


namespace ProgressMonitoringProject.Controllers
{

    [RoutePrefix("api/users")]
    public class UsersController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetAll()

        {
            var data = await (
           from u in db.Users
           join s in db.Students
           on u.id equals s.regNum
           select new
           {
               id = u.id,
               name = u.name,
               email = u.email,
               role = u.role,
               regNum = s.regNum,
               selectedTech = s.selectedTech
           }
   ).ToListAsync();
            return Ok(data);
        }

        [HttpGet]
        [Route("student/{regNum}")]
        public async Task<IHttpActionResult> GetStudent(string regNum)
        {
            //if (string.IsNullOrWhiteSpace(regNum))
            //    return BadRequest("Registration number is required.");

            //var student = await db.Students.FindAsync(regNum);

            //if (student == null)
            //    return NotFound();

            return Ok("heheheh");
        }

        [HttpGet, Route("by-student/{regNum}")]
        public IHttpActionResult GetByStudent(string regNum)
        {
            var list1 = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name


            }).FirstOrDefault();
            var list = db.Enrollments.Where(x => x.studentID == regNum && x.sessionID == list1.id ).Select(e=> new {
            
            e.studentID,
            e.sessionID,
            e.grade,
            e.subject
            
            
            }).FirstOrDefault();


            if (list == null)
                return BadRequest("Request not found");
            return Ok(list);
        }



        [HttpGet, Route("CurrentSession")]
        public IHttpActionResult GetCurrentSession()
        {
            var list = db.Sessions.OrderByDescending(o=>o.id).Select(e => new {

               e.id,
               e.name


            }).FirstOrDefault();
            return Ok(list);
        }



        // GET: api/students?dept=CS&section=7A&techId=1
        [HttpGet]
        [Route("StudentDetails/{regNum}")]
        public async Task<IHttpActionResult> GetStudents(string regNum)
        {
            var students = await db.Students.Where(s => s.regNum == regNum).Select(s => new
            {

                regNum = s.regNum,
                name = s.name,
                gender = s.gender,
                currentCGPA = s.currentCGPA,

                DepartmentId = s.Department.id,
                DepartmentName = s.Department.name,

                TechnologyId = s.Technology.id,
                TechnologyName = s.Technology.name,

                SessionId = s.Session.id,
                SessionName = s.Session.name,

                SectionId = s.Section.id,
                SectionName = s.Section.name,
                semesterNo = s.semesterNo,
                Subject = db.Enrollments.Where(e => e.studentID == s.regNum && e.sessionID == db.Sessions.OrderByDescending(o => o.id).Select(x => x.id).FirstOrDefault()).Select(a => a.subject).FirstOrDefault()



            }).ToListAsync();

            return Ok(students);
        }


        [HttpGet]
[Route("StudentByTech/{techName}/{regNum}")]
public async Task<IHttpActionResult> GetStudentsByTech(string techName, string regNum)
{
            var Subject = db.Enrollments.Where(e => e.studentID == regNum && e.sessionID == db.Sessions.OrderByDescending(o => o.id).Select(x => x.id).FirstOrDefault()).Select(a => a.subject).FirstOrDefault();

    var students = await db.Students
        .Where(s => 
            s.Technology.name != (string)techName          // Different Technology
            && s.regNum != (string)regNum                 // Not the logged-in student
            && !db.GroupMembers.Any(g => g.studentID == s.regNum)  // Not already in group
            && db.Enrollments.Any(e => e.studentID == s.regNum && e.sessionID == db.Sessions.OrderByDescending(o => o.id).Select(x => x.id).FirstOrDefault() && e.subject==db.Enrollments.Where(w=> w.subject==Subject).Select(a=>a.subject).FirstOrDefault()) // Enrolled in current session with passing grade
        )
        .Select(s => new
        {
            regNum = s.regNum,
            name = s.name,
            gender = s.gender,
            currentCGPA = s.currentCGPA,

            DepartmentId = s.Department.id,
            DepartmentName = s.Department.name,

            TechnologyId = s.Technology.id,
            TechnologyName = s.Technology.name,

            SessionId = s.Session.id,
            SessionName = s.Session.name,
            SectionId = s.Section.id,
            SectionName = s.Section.name,
            semesterNo = s.semesterNo
        })
        .ToListAsync();

    return Ok(students);
}


        [HttpPost]
        [Route("CreateGroup")]
        public async Task<IHttpActionResult> InsertProjectAssignment(ProjectGroup model)
        {
            if (model == null)
                return BadRequest("Invalid data");
            var IsExist = db.GroupMembers.Any(g => g.studentID == model.createdBy);
            if (!IsExist)
            {

                db.ProjectGroups.Add(new ProjectGroup
                {
                    createdBy = model.createdBy,
                    supervisorID = model.supervisorID,
                    projectID = model.projectID,
                    isFinalized = model.isFinalized,
                    createdSession = model.createdSession
                });
                await db.SaveChangesAsync();
                db.GroupMembers.Add(new GroupMember
                {
                    groupID = db.ProjectGroups.Where(g => g.createdBy == model.createdBy).Select(x => x.id).FirstOrDefault(),
                    studentID = model.createdBy,
                    isAdmin = 1
                });

                await db.SaveChangesAsync();
            }
            return Ok(new
            {
                message = "Project assignment inserted successfully"
            });
        }


        [HttpGet]
        [Route("GetMyGroup/{regNum}")]
        public IHttpActionResult GetMyGroup(string regNum)
        {

            var list1 = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name


            }).FirstOrDefault();
            var group = db.GroupMembers
                .Where(x => x.studentID == regNum && x.ProjectGroup.createdSession == list1.id)
                .Select(x => new
                {
                    groupId = x.groupID,
                    studentId = x.studentID,

                    members = db.GroupMembers
                        .Where(m => m.groupID == x.groupID)
                        .Select(m => new
                        {
                            regNum = m.studentID,
                            name=m.Student.name,
                            Cgpa = m.Student.currentCGPA,
                            technology=m.Student.Technology.name,
                            isAdmin = m.isAdmin
                        }).ToList().Distinct()
                })
                .FirstOrDefault();

            return Ok(group);
        }
     
        [HttpPost]
        [Route("RespondGroupRequest")]
        public async Task<IHttpActionResult> RespondGroupRequest(GroupResponseModel model)
        {
            var request = db.GroupRequestMembers.FirstOrDefault(x => x.RequestID == model.RequestID && x.MemberRegNum == model.RegNum);

            if (request == null)
                return BadRequest("Request not found");

            request.Status = model.Status; // Accepted / Rejected
            await db.SaveChangesAsync();

            return Ok(new { message = "Response updated" });
        }


        [HttpGet]
        [Route("GetGroupRequests/{regNum}")]
        public IHttpActionResult GetGroupRequests(string regNum)
        {

            var list1 = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name

            }).FirstOrDefault();

            var requests = db.GroupRequestMembers
                .Where(x => x.GroupRequest.FromRegNum == regNum && x.GroupRequest.SessionID ==list1.id)
                .Select(x => new
                {
                    x.RequestID,
                    x.MemberRegNum,
                    x.Status
                }).ToList();

            return Ok(requests);
        }

        [HttpGet]
        [Route("GetMemberRequests/{regNum}")]
        public IHttpActionResult GetMemberRequests(string regNum)
        {
            var requests = db.GroupRequestMembers
                .Where(x => x.MemberRegNum == regNum && x.Status=="Pending")
                .Select(x => new
                {
                    x.RequestID,
                    x.GroupRequest.FromRegNum,
                    x.Status
                }).ToList();

            return Ok(requests);
        }

        [HttpPost]
        [Route("FinalizeGroup")]
        public async Task<IHttpActionResult> FinalizeGroup(FinalizeGroupModel model)
        {
            var group = db.ProjectGroups.Find(model.GroupId);

            if (group == null)
                return BadRequest("Group not found");

            group.isFinalized = 1;
            await db.SaveChangesAsync();

            return Ok(new { message = "Group finalized" });
        }
        [HttpGet]
        [Route("IsFinalized/{regNum}")]
        public async Task<IHttpActionResult> IsFinalized(string regNum)
        {
             //Get group ID of student
            var groupId = await db.GroupMembers
                 .Where(g => g.studentID == regNum)
                 .Select(g => new { g.groupID })
                 .FirstOrDefaultAsync();

            // if (groupId == 0)
            //     return NotFound();
            // // Get finalized status
            // var isFinalized = await db.ProjectGroups
            //     .Where(g => g.id == groupId)
            //     .Select(g => g.isFinalized)
            //     .FirstOrDefaultAsync();

            var isFinalized = db.ProjectGroups.Where(g => g.id == groupId.groupID).Select(x =>
                new
                {

                    x.isFinalized
                }



                ).FirstOrDefault();





            return Ok(isFinalized);
        }
        [HttpGet]
        [Route("IsInGroup/{regNum}")]
        public async Task<IHttpActionResult> IsInGroup(string regNum)
        {
            bool exists = await db.GroupMembers
                .AnyAsync(g => g.studentID == regNum);

            return Ok(exists);
        }

        [HttpGet]
        [Route("IsAdmin/{regNum}")]
        public async Task<IHttpActionResult> IsAdmin(string regNum)
        {
            bool exists = await db.GroupMembers
                .AnyAsync(g => g.studentID == regNum && g.isAdmin==1);
            
            return Ok(exists);
        }

        [HttpGet]
        [Route("getAllDepartments")]
        public async Task<IHttpActionResult> getAllDepartments()
        {
            var list = db.Departments.Select(x => new
            {
                x.id,
                x.name


            });
            if (list == null) return NotFound();

            return Ok(list);

        }

        [HttpGet]
        [Route("getAllSections")]
        public async Task<IHttpActionResult> getAllSections()
        {
            var list = await db.Sections
                .Select(x => new
                {
                    id = x.id,
                    name = x.name
                })
                .Distinct()
                .ToListAsync();

            return Ok(list);
        }


        [HttpDelete]
        [Route("RemoveGroupMember")]
        public async Task<IHttpActionResult> RemoveGroupMember(RemoveMemberModel model)
        {
            var member = db.GroupMembers
                .FirstOrDefault(x => x.groupID == model.GroupId &&
                                     x.studentID == model.MemberRegNum);

            if (member == null)
                return BadRequest("Member not found");

            db.GroupMembers.Remove(member);
            await db.SaveChangesAsync();

            return Ok(new { message = "Member removed" });
        }

        [HttpPost]
        [Route("UpdateSelectedTech/{id}")]
        public async Task<IHttpActionResult> UpdateSelectedTech(string id, UpdateSelectedTechModel model)
        {
            if (model == null || model.SelectedTech == null)
                return BadRequest("Invalid data");

            // Find student (or user)
            var user = await db.Students.FirstOrDefaultAsync(s => s.regNum == id);

            if (user == null)
                return NotFound();

            // Update selected technology
            user.selectedTech = model.SelectedTech;

            await db.SaveChangesAsync();

            return Ok(new
            {
                message = "Technology updated successfully",
                selectedTech = user.selectedTech
            });
        }



        [HttpPost]
        [Route("CreateGroupRequest")]
        public async Task<IHttpActionResult> CreateGroupRequest(GroupRequestModel model)
        {
            if (model == null || model.members == null || !model.members.Any())
                return BadRequest("Invalid data");

            // 1️⃣ Insert into GroupRequests table
            var groupRequest = new GroupRequest
            {
                FromRegNum = model.fromRegNum,
                SessionID = model.sessionId
            };

            db.GroupRequests.Add(groupRequest);
            await db.SaveChangesAsync();

            // 2️⃣ Insert members into GroupRequestMembers table
            foreach (var member in model.members)
            {
                db.GroupRequestMembers.Add(new GroupRequestMember
                {
                    RequestID = groupRequest.RequestID,
                    MemberRegNum = member,
                    Status = "Pending"
                });
            }

            await db.SaveChangesAsync();

            return Ok(new
            {
                message = "Group request created successfully"
            });
        }


        [HttpGet]
        [Route("login")]
        public async Task<IHttpActionResult> Login(string id, string password)
        {
            // Check user exists
            var user = await db.Users.FindAsync(id);
            if (user == null)
                return NotFound();
            if (user.password == password)
            {

                // ================= OTHER ROLES =================
                return Ok(new
                {
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    password = user.password,

                    role = user.role
                });
            }
            return NotFound();
        }

        [HttpGet]
        [Route("allTech")]
        public IHttpActionResult GetAllTech()
        {
            return Ok(db.Technologies.Select(x=> new
            {

                x.id,
                x.name



            }).ToList()
            
                
                );
        }


        [HttpGet]
        [Route("{id}")]
        public async Task<IHttpActionResult> Get(string id)

        {
            // Check user exists
            var user = await db.Users.FindAsync(id);
            if (user == null)
                return NotFound();

            // ================= STUDENT =================
            if (user.role == "Student")
            {
                var data = await (
                    from u in db.Users
                    join s in db.Students

                        on u.id equals s.regNum
                    where u.id == id
                    select new
                    {
                        id = u.id,
                        name = u.name,
                        email = u.email,
                        role = u.role,
                        password = u.password,
                        regNum = s.regNum,
                        selectedTech = s.selectedTech,
                        admissionSession = s.admissionSession,
                        currentCGPA = s.currentCGPA,
                        gender = s.gender,
                        studentDepartment = s.studentDepartment

                    }
                ).FirstOrDefaultAsync();   // 🔥 IMPORTANT

                if (data == null)
                    return NotFound();

                return Ok(data);   // ✅ OBJECT
            }

            // ================= OTHER ROLES =================
            return Ok(new
            {
                id = user.id,
                name = user.name,
                email = user.email,
                password = user.password,

                role = user.role
            });
        }

        [HttpGet]
        [Route("tech/{id}")]
        public async Task<IHttpActionResult> GetStudentTech(int id)

        {

            var student = await db.Technologies.FindAsync(id);
            if (student == null) return NotFound();

            return Ok(new
            {
                id = student.id,
                name = student.name
            });
        }



        [HttpPost, Route("")]
        public async Task<IHttpActionResult> Create([FromBody] User user)
        {
            if (user == null || string.IsNullOrEmpty(user.id)) return BadRequest("Invalid user payload.");

            var exists = await db.Users.FindAsync(user.id);
            if (exists != null) return BadRequest("User with this id already exists.");

            db.Users.Add(user);
            await db.SaveChangesAsync();

            user.password = null;
            return Ok(user);
        }

        [HttpPut, Route("{id}")]
        public async Task<IHttpActionResult> Update(string id, [FromBody] User updated)
        {
            if (updated == null || id != updated.id) return BadRequest("Invalid payload.");

            var user = await db.Users.FindAsync(id);
            if (user == null) return NotFound();


            user.name = updated.name;
            user.email = updated.email;
            user.role = updated.role;

            if (!string.IsNullOrEmpty(updated.password)) user.password = updated.password;

            db.Entry(user).State = EntityState.Modified;
            await db.SaveChangesAsync();

            user.password = null;
            return Ok(user);
        }


        [HttpDelete, Route("{id}")]
        public async Task<IHttpActionResult> Delete(string id)
        {
            var user = await db.Users.FindAsync(id);
            if (user == null) return NotFound();


            db.Users.Remove(user);
            try
            {
                await db.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                return BadRequest("Unable to delete user. Remove dependent records first. " + ex.Message);
            }

            return Ok();
        }


        [HttpGet, Route("role/{role}")]
        public async Task<IHttpActionResult> GetByRole(string role)
        {
            var list = await db.Users.Where(u => u.role == role).ToListAsync();
            var sanitized = list.Select(u => new
            {
                id = u.id,
                name = u.name,
                email = u.email,
                role = u.role
            });
            return Ok(sanitized);
        }




        [HttpPost]
        [Route("UpdateGroupRequestStatus")]
        public async Task<IHttpActionResult> UpdateGroupRequestStatus(UpdateGroupRequestStatusModel model)
        {
            if (model == null || string.IsNullOrEmpty(model.Status))
                return BadRequest("Invalid data");


            var request = await db.GroupRequests.Where(r => r.RequestID == model.RequestId).Select(r => new
            {
                r.FromRegNum,

            }).FirstOrDefaultAsync();

            var groupId = await db.GroupMembers.Where(gm => gm.studentID == request.FromRegNum)
                .Select(gm => gm.groupID)
                .FirstOrDefaultAsync();
            // Get all request members
            var requestMembers = await db.GroupRequestMembers
                .Where(m => m.RequestID == model.RequestId)
                .ToListAsync();

            if (!requestMembers.Any())
                return NotFound();

            // Update status
            foreach (var m in requestMembers)
            {
                m.Status = model.Status;
            }

            // ✅ If Accepted → add to ProjectGroupMember table
            if (model.Status == "Accepted")
            {
                foreach (var m in requestMembers) {
                    db.GroupMembers.Add(new GroupMember {

                        groupID = groupId,
                        studentID = m.MemberRegNum,
                        isAdmin=0,

                    });



                }




            }

            await db.SaveChangesAsync();

            return Ok(new
            {
                message = "Request status updated and members added to group successfully",
                status = model.Status
            });
        }















        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }

    }
    public class UpdateGroupRequestStatusModel
    {
        public int RequestId { get; set; }
        public string Status { get; set; }  // Accepted / Rejected
    }

    public class UpdateSelectedTechModel
    {
        public int SelectedTech { get; set; }
    }

    public class GroupRequestModel
    {
        public string fromRegNum { get; set; }
        public int sessionId { get; set; }
        public List<string> members { get; set; }
    }

    public class GroupResponseModel
    {
        public int RequestID { get; set; }
        public string RegNum { get; set; }
        public string Status { get; set; }
    }

    public class RemoveMemberModel
    {
        public int GroupId { get; set; }
        public string MemberRegNum { get; set; }
    }

    public class FinalizeGroupModel
    {
        public int GroupId { get; set; }
    }

}
