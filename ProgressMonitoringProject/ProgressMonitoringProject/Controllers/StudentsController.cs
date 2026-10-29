using ProgressMonitoringProject.Models;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Data.Entity;
using System.Collections.Generic;
using System;
using static ProgressMonitoringProject.Controllers.NotificationsController;
using System.Web.Http.Results;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/students")]
    public class StudentsController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();


        [HttpGet]
        [Route("tasks/{id}")]
        public IHttpActionResult GetTaskById(int id)
        {
            var task = db.Tasks
                .Where(t => t.id == id)
                .Select(t => new
                {
                    t.id,
                    t.title,
                    t.taskDescription,
                    t.assignDate,
                    t.dueDate,
                    t.taskStatus,
                    t.isPptRequired,
                    submissionFilePath = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => te.submissionFilePath).FirstOrDefault(),
                    progress = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => (int?)te.score).FirstOrDefault() ?? 0,
                    remarks = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => te.taskRemarks).FirstOrDefault(),
                })
                .FirstOrDefault();

            if (task == null)
                return NotFound();

            return Ok(task);
        }
        [HttpGet]
        [Route("getNotifications/{studentId}")]
        public IHttpActionResult GetStudentNotifications(string studentId)
        {
            try
            {
                var notifications = (
                    from nr in db.NotificationRecipients
                    join n in db.Notifications on nr.NotificationID equals n.NotificationID
                    where nr.RecipientID == studentId
                    orderby n.CreatedAt descending
                    select new
                    {
                        id = n.NotificationID,
                        title = n.Title,
                        message = n.Message,
                        createdAt = n.CreatedAt,
                        isRead = nr.IsRead
                    }
                ).ToList();

                return Ok(notifications);
            }
            catch (Exception)
            {
                return InternalServerError(new Exception("Error fetching notifications"));
            }
        }
        [HttpGet]
        [Route("eligible-groups/{studentId}")]
        public IHttpActionResult GetEligibleGroups(string studentId)
        {
            try
            {
                // 🔹 1. Get current session
                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                // 🔹 2. Get student info
                var student = db.Students
                    .Where(s => s.regNum == studentId)
                    .Select(s => new
                    {
                        s.regNum,
                        s.selectedTech,
                        TechName = s.Technology.name
                    })
                    .FirstOrDefault();

                if (student == null)
                    return BadRequest("Student not found");

                // 🔹 3. Check if already in a group
                var alreadyInGroup = db.GroupMembers
                    .Any(g => g.studentID == studentId);

                if (alreadyInGroup)
                    return BadRequest("Student already in a group");

                // 🔹 4. Get student's FYP type (FYP-1 / FYP-2)
                var studentFyp = db.Enrollments
                    .Where(e => e.studentID == studentId && e.sessionID == currentSessionId)
                    .Select(e => e.subject)
                    .FirstOrDefault();

                // 🔹 5. Get eligible groups
                var groups = db.ProjectGroups
                    .Where(g => g.createdSession == currentSessionId)
                    .Where(g =>
                        db.GroupMembers
                            .Where(m => m.groupID == g.id)
                            .All(m => m.Student.selectedTech != student.selectedTech) // ❌ same tech not allowed
                    )
                    .Where(g =>
                        db.GroupMembers.Any(m =>
                            m.groupID == g.id &&
                            db.Enrollments.Any(e =>
                                e.studentID == m.studentID &&
                                e.sessionID == currentSessionId &&
                                e.subject == studentFyp // ✅ same FYP type
                            )
                        )
                    )
                    .Select(g => new
                    {
                        groupId = g.id,

                        members = g.GroupMembers.Select(m => new
                        {
                            m.Student.name,
                            m.Student.regNum,
                            Technology = m.Student.Technology.name,
                            gender = m.Student.gender
                        }).ToList(),

                        memberCount = g.GroupMembers.Count()
                    })
                    .ToList();

                return Ok(groups);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("")]
        public async Task<IHttpActionResult> GetAllStudents()
        {
            var students = await db.Students
                .Select(s => new
                {
                    regNum = s.regNum,
                    name = s.name,
                    gender = s.gender,
                    admissionSession = s.admissionSession,
                    currentCGPA = s.currentCGPA,
                    studentDepartment = s.studentDepartment,
                    selectedTech = s.selectedTech
                })
                .ToListAsync();

            return Ok(students);
        }
        [HttpGet]
        [Route("{regNum}")]
        public async Task<IHttpActionResult> GetAllStudents(string regNum)
        {
            var students = await db.Students.Where(s => s.regNum == regNum)
                .Select(s => new
                {
                    regNum = s.regNum,
                    name = s.name,
                    gender = s.gender,
                    admissionSession = s.Session.name,
                    currentCGPA = s.currentCGPA,
                    studentDepartment = s.Department.name,
                    selectedTech = s.Technology.name,
                    FypType = db.Enrollments.Where(x => x.studentID == s.regNum).Select(x => x.subject).FirstOrDefault(),
                    GroupId = db.GroupMembers.Where(x => x.studentID == s.regNum).Select(x => x.groupID).FirstOrDefault(),
                    Project = db.ProjectGroups.Where(x => x.id == db.GroupMembers.Where(x => x.studentID == s.regNum).Select(x => x.groupID).FirstOrDefault()).Select(x => x.OfferedProject.Project.title).FirstOrDefault(),
                    Supervisor = db.Users.Where(u => u.id == db.ProjectGroups.Where(x => x.id == db.GroupMembers.Where(x => x.studentID == s.regNum).Select(x => x.groupID).FirstOrDefault()).Select(x => x.supervisorID).FirstOrDefault()).Select(s => s.name).FirstOrDefault()


                })
                .FirstOrDefaultAsync();

            return Ok(students);
        }


        public class NotificationDto
        {
            public int Id { get; set; }

            public string Title { get; set; }
            public string Message { get; set; }

            public string Type { get; set; }
            public int ReferenceID { get; set; }

            public DateTime CreatedAt { get; set; }

            public int IsRead { get; set; }
        }


        [HttpPost]
        [Route("updatePassword")]
        public async Task<IHttpActionResult> Put(string id, string password)
        {
            var student = await db.Users.FindAsync(id);
            if (student == null)
                return NotFound();

            //student.gender = dto.Gender;
            //student.currentCGPA = dto.CurrentCGPA;
            //student.selectedTech = db.Technologies.Where(x => x.name.Equals( dto.SelectedTech)).Select(s => s.id).FirstOrDefault();

            if (!string.IsNullOrEmpty(password))
                student.password = password;

            await db.SaveChangesAsync();

            return Ok();
        }


        [HttpDelete, Route("{regNum}")]
        public IHttpActionResult Delete(string regNum)
        {
            var st = db.Students.Find(regNum);
            if (st == null) return NotFound();

            db.Students.Remove(st);
            db.SaveChanges();
            return Ok();
        }


        [HttpGet, Route("by-department/{depId}")]
        public IHttpActionResult GetByDepartment(int depId)
        {
            var list = db.Students.Where(x => x.studentDepartment == depId).ToList();
            return Ok(list);
        }


        [HttpGet, Route("by-session/{sessionId}")]
        public IHttpActionResult GetBySession(int sessionId)
        {
            var list = db.Students.Where(x => x.admissionSession == sessionId).ToList();
            return Ok(list);
        }

        [HttpGet, Route("by-tech/{techId}")]
        public IHttpActionResult GetByTech(int techId)
        {
            var list = db.Students.Where(x => x.selectedTech == techId).ToList();
            return Ok(list);
        }


        [HttpGet, Route("is-in-group/{regNum}")]
        public IHttpActionResult IsStudentInGroup(string regNum)
        {
            bool exists = db.GroupMembers.Any(x => x.studentID == regNum);
            return Ok(new { inGroup = exists });
        }


        //[HttpGet, Route("fyp1-status/{regNum}")]
        //public IHttpActionResult GetFyp1Status(string regNum)
        //{
        //    var scores = db.FYP1Score.Where(x => x.groupMemberID ==
        //        db.GroupMembers.FirstOrDefault(g => g.studentID == regNum).id).ToList();

        //    if (!scores.Any()) return Ok(new { status = "Not Evaluated" });

        //    int total = (int)scores.Sum(x => x.score);
        //    bool passed = total >= 50;

        //    return Ok(new { totalScore = total, passed });
        //}

        //[HttpPost, Route("promote-fyp2/{regNum}")]
        //public IHttpActionResult PromoteToFyp2(string regNum)
        //{
        //    var member = db.GroupMembers.FirstOrDefault(g => g.studentID == regNum);
        //    if (member == null) return BadRequest("Student is not part of a group.");

        //    var scores = db.FYP1Score.Where(x => x.groupMemberID == member.id).ToList();

        //    if (!scores.Any()) return BadRequest("Student has no FYP-1 evaluation.");

        //    int total = (int)scores.Sum(x => x.score);
        //    if (total < 50) return BadRequest("Cannot promote — student failed FYP-1.");

        //    return Ok(new { promoted = true });
        //}


        [HttpPost]
        [Route("update-technologies/{groupId}")]
        public async Task<IHttpActionResult> UpdateTechnologies(
    int groupId,
     UpdateTechDto model)
        {
            if (model == null || model.Students == null)
                return BadRequest("Invalid data");

            try
            {
                foreach (var student in model.Students)
                {
                    var dbStudent = await db.Students
                        .FirstOrDefaultAsync(s => s.regNum == student.RegNum);

                    if (dbStudent != null)
                    {
                        dbStudent.selectedTech = student.TechnologyId;
                    }
                }

                await db.SaveChangesAsync();

                return Ok("Technologies updated successfully");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        //[HttpGet]
        //[Route("details/{studentId}")]
        //public IHttpActionResult GetStudentDetails(string studentId)
        //{
        //    var student = db.Students
        //        .Where(s => s.regNum == studentId)
        //        .Select(s => new
        //        {
        //            s.regNum,
        //            s.name,
        //            s.gender,
        //            s.currentCGPA,
        //            admissionSession = new
        //            {
        //                s.admissionSession,
        //                sessionName = s.Session.name,
        //                s.Session.startDate
        //            },
        //            department = new
        //            {
        //                s.studentDepartment,
        //                deptName = s.Department.name
        //            },
        //            selectedTechnology = new
        //            {
        //                s.selectedTech,
        //                techName = s.Technology.name
        //            },


        //            enrollments = s.Enrollments.Select(e => new
        //            {
        //                e.subject,
        //                e.grade,
        //                sessionName = e.Session.name
        //            }).ToList(),

        //            groups = s.GroupMembers.Select(gm => new
        //            {
        //                gm.groupID,
        //                group = new
        //                {
        //                    gm.ProjectGroup.id,
        //                    gm.ProjectGroup.createdBy,
        //                    createdByName = gm.ProjectGroup.User.name,
        //                    supervisorId = gm.ProjectGroup.supervisorID,
        //                    supervisorName = gm.ProjectGroup.User.name,
        //                    projectId = gm.ProjectGroup.projectID
        //                },
        //                requestStatus = gm.requestStatus
        //            }).ToList(),

        //            tasks = s.Tasks.Select(t => new
        //            {
        //                t.id,
        //                t.title,
        //                t.taskDescription,
        //                t.assignDate,
        //                t.dueDate,
        //                t.isPptRequired,
        //                t.taskStatus,
        //                assignedByName = t.User.name,
        //                groupId = t.groupID,
        //                evaluations = t.TaskEvaluations.Select(te => new
        //                {
        //                    te.id,
        //                    te.taskRemarks,
        //                    te.submissionFilePath,
        //                    te.submissionDate
        //                }).ToList()
        //            }).ToList(),

        //            fyp2Tasks = s.Fyp2TaskEvaluation.Select(f2 => new
        //            {
        //                f2.id,
        //                taskId = f2.taskID,
        //                f2.remarks,
        //                evaluatorName = f2.User.name,
        //                fyp2TaskDetails = new
        //                {
        //                    f2.Fyp2Task.id,
        //                    f2.Fyp2Task.taskDescription,
        //                    f2.Fyp2Task.sessionID
        //                }
        //            }).ToList(),

        //            supervisorAttendance = db.SuperVisorAttendances
        //                .Where(sa => sa.SuperVisorMeeting.ProjectGroup.GroupMembers.Any(gm => gm.studentID == studentId))
        //                .Select(sa => new
        //                {
        //                    sa.id,
        //                    sa.attendanceDate,
        //                    sa.meetingID,
        //                    isAttend = sa.isAttend
        //                }).ToList(),

        //            meetingAttendance = db.MeetingAttendances
        //                .Where(ma => ma.studentID.ToString() == studentId)
        //                .Select(ma => new
        //                {
        //                    ma.id,
        //                    ma.scheduleID,
        //                    ma.attendance,
        //                    ma.remarks
        //                }).ToList(),

        //            queueAttendance = db.MeetingQueueAttendances
        //                .Where(qa => qa.memberID.ToString() == studentId)
        //                .Select(qa => new
        //                {
        //                    qa.id,
        //                    qa.meetingQueueID,
        //                    qa.isPresent
        //                }).ToList(),

        //            supervisorNotifications = db.SupNotBroadCasts
        //                .Where(sn => sn.studentID == studentId)
        //                .Select(sn => new
        //                {
        //                    sn.id,
        //                    sn.meetingID,
        //                    sn.notStatus
        //                }).ToList(),



        //            fyp1Scores = db.FYP1Score
        //                .Where(f1 => f1.groupMemberID == db.GroupMembers
        //                    .Where(gm => gm.studentID == studentId)
        //                    .Select(gm => gm.id).FirstOrDefault())
        //                .Select(f1 => new
        //                {
        //                    f1.id,
        //                    f1.score,
        //                    f1.parameterID,
        //                    f1.sessionID
        //                }).ToList(),

        //            fyp2Scores = db.FYP2Score
        //                .Where(f2 => f2.groupMemberID == db.GroupMembers
        //                    .Where(gm => gm.studentID == studentId)
        //                    .Select(gm => gm.id).FirstOrDefault())
        //                .Select(f2 => new
        //                {
        //                    f2.id,
        //                    f2.score,
        //                    f2.evaluatorID,
        //                    f2.sessionID
        //                }).ToList()
        //        })
        //        .FirstOrDefault();

        //    if (student == null) return NotFound();

        //    return Ok(student);
        //}
        [HttpGet]
        [Route("current-semester/{studentId}")]
        public IHttpActionResult GetCurrentSemester(string studentId)
        {
            try
            {
                // =========================
                // STUDENT
                // =========================
                var student = db.Students
                    .FirstOrDefault(s => s.regNum == studentId);

                if (student == null)
                    return NotFound();

                // =========================
                // ADMISSION SESSION
                // =========================
                var admissionSession = db.Sessions
                    .FirstOrDefault(s => s.id == student.admissionSession);

                // =========================
                // CURRENT SESSION
                // =========================
                var currentSession = db.Sessions
                    .OrderByDescending(s => s.id)
                    .FirstOrDefault();

                if (currentSession == null)
                    return BadRequest("No current session found");

                // =========================
                // CALCULATE SEMESTER
                // =========================
                int currentSemester =
                    (currentSession.id - (student.admissionSession ?? 0)) + 1;

                if (currentSemester < 1)
                    currentSemester = 1;

                // =========================
                // RESPONSE
                // =========================
                return Ok(new
                {
                    studentId = student.regNum,
                    studentName = student.name,

                    admissionSession = admissionSession != null
                        ? admissionSession.name
                        : "",

                    currentSession = currentSession.name,

                    semester = currentSemester
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

    }


    

    public class StudentUpdateDto
    {

        public string Password { get; set; }
    }
    public class UpdateTechDto
    {
        public List<StudentTechDto> Students { get; set; }
    }

    public class StudentTechDto
    {
        public string RegNum { get; set; }
        public int TechnologyId { get; set; }
    }
}
