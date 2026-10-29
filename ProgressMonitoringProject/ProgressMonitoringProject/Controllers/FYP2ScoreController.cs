using ProgressMonitoringProject.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using static ProgressMonitoringProject.Controllers.CommitteeMeetingsController;
using static ProgressMonitoringProject.Controllers.FYP1ScoreController;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/fyp2-scores")]
    public class FYP2ScoreController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        //[HttpGet, Route("")]
        //public IHttpActionResult GetAll() => Ok(db.FYP2Score.ToList());

        //[HttpGet, Route("{id}")]
        //public IHttpActionResult Get(int id)
        //{
        //    var s = db.FYP2Score.Find(id);
        //    if (s == null) return NotFound();
        //    return Ok(s);
        //}

        //[HttpPost, Route("")]
        //public IHttpActionResult Create([FromBody] FYP2Score score)
        //{
        //    if (!ModelState.IsValid) return BadRequest(ModelState);
        //    db.FYP2Score.Add(score);
        //    db.SaveChanges();
        //    return Ok(score);
        //}

        //[HttpPut, Route("{id}")]
        //public IHttpActionResult Update(int id, [FromBody] FYP2Score updated)
        //{
        //    if (id != updated.id) return BadRequest("Id mismatch");
        //    db.Entry(updated).State = EntityState.Modified;
        //    db.SaveChanges ();
        //    return Ok(updated);
        //}

        //[HttpDelete, Route("{id}")]
        //public IHttpActionResult Delete(int id)
        //{
        //    var s =   db.FYP2Score.Find (id);
        //    if (s == null) return NotFound();
        //    db.FYP2Score.Remove(s);
        //      db.SaveChanges ();
        //    return Ok();
        //}

        [HttpPost]
        [Route("assign-parameters-to-meeting")]
        public IHttpActionResult AssignParametersToMeeting(Fyp2AssignParametersDto dto)
        {
            foreach (var paramId in dto.ParameterIds)
            {
                db.Fyp2MeetingMapping.Add(new Fyp2MeetingMapping
                {
                    meetingID = dto.MeetingId,
                    parameterID = paramId
                });
            }

            db.SaveChanges();
            return Ok("Parameters assigned to meeting");
        }
        [HttpGet]
        [Route("get/{studentEnrollID}/{meetingID}/{evaluatorID}/{sessionID}")]
        public IHttpActionResult GetRemarks(
    int studentEnrollID,
    int taskID,
    string evaluatorID,
    int sessionID)
        {
            var remark = db.Fyp2StudentEvaluationRemarks.FirstOrDefault(r =>
                r.studentEnrollID == studentEnrollID &&
                r.taskID == taskID &&
                r.evaluatorID == evaluatorID &&
                r.sessionID == sessionID
            );

            if (remark == null)
            {
                return Ok(new
                {
                    exists = false,
                    remarks = "",
                    evaluatorID = evaluatorID,
                    createdAt = (string)null
                });
            }

            return Ok(new
            {
                exists = true,
                remarks = remark.remarks,
                evaluatorID = remark.evaluatorID,
                createdAt = remark.createdAt
            });
        }
        // DTO for meeting-based (non-task) FYP-2 remarks
        public class Fyp2MeetingRemarkDto
        {
            public int StudentEnrollID { get; set; }
            public int MeetingID { get; set; }
            public string EvaluatorID { get; set; }
            public int SessionID { get; set; }
            public string Remarks { get; set; }
        }

        // Endpoint used by CommitteeHead screen (meetingID-based, no taskID required)
        [HttpPost]
        [Route("save-or-update")]
        public IHttpActionResult SaveOrUpdateFyp2Remark(Fyp2MeetingRemarkDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Remarks))
                return BadRequest("Invalid remarks data");

            // Look up existing remark by enrollmentID + evaluatorID + sessionID
            var existing = db.Fyp2StudentEvaluationRemarks.FirstOrDefault(r =>
                r.studentEnrollID == dto.StudentEnrollID &&
                r.evaluatorID == dto.EvaluatorID &&
                r.sessionID == dto.SessionID
            );

            if (existing != null)
            {
                existing.remarks = dto.Remarks;
            }
            else
            {
                db.Fyp2StudentEvaluationRemarks.Add(new Fyp2StudentEvaluationRemarks
                {
                    studentEnrollID = dto.StudentEnrollID,
                    taskID = null,   // no task context from CommitteeHead meeting screen
                    evaluatorID = dto.EvaluatorID,
                    sessionID = dto.SessionID,
                    remarks = dto.Remarks,
                    createdAt = DateTime.Now
                });
            }

            db.SaveChanges();
            return Ok(new { Message = "Remarks saved successfully" });
        }

        [HttpGet]
        [Route("get-remarks/{studentEnrollID}/{evaluatorID}/{sessionID}")]
        public IHttpActionResult GetAllRemarksByEvaluator(int studentEnrollID, string evaluatorID, int sessionID)
        {
            try
            {
                var remarks = db.Fyp2StudentEvaluationRemarks
                    .Where(r =>
                        r.studentEnrollID == studentEnrollID &&
                        r.evaluatorID == evaluatorID &&
                        r.sessionID == sessionID
                    )
                    .OrderByDescending(r => r.createdAt)
                    .Select(r => new
                    {
                        r.id,
                        r.taskID,
                        r.remarks,
                        r.createdAt,
                        // Provide a fallback updatedAt to match frontend expectations
                        updatedAt = r.createdAt
                    })
                    .ToList();

                return Ok(remarks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("save")]
        public IHttpActionResult SaveRemarks(StudentEvaluationRemarkDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Remarks))
                return BadRequest("Invalid remarks data");

            var existing = db.Fyp2StudentEvaluationRemarks.FirstOrDefault(r =>
                r.studentEnrollID == dto.StudentEnrollID &&
                r.taskID == dto.taskID &&
                r.evaluatorID == dto.EvaluatorID &&
                r.sessionID == dto.SessionID
            );

            if (existing != null)
            {
                // 🔄 Update
                existing.remarks = dto.Remarks;
            }
            else
            {
                // ➕ Insert
                var remark = new Fyp2StudentEvaluationRemarks
                {
                    studentEnrollID = dto.StudentEnrollID,
                    taskID = dto.taskID,
                    evaluatorID = dto.EvaluatorID,
                    sessionID = dto.SessionID,
                    remarks = dto.Remarks,
                    createdAt = DateTime.Now
                };

                db.Fyp2StudentEvaluationRemarks.Add(remark);
            }
            db.SaveChanges();

            return Ok(new
            {
                Message = "Remarks saved successfully"
            });
        }

        [HttpGet]
        [Route("evaluation-panel/{meetingId}")]
        public IHttpActionResult GetEvaluationPanel(int meetingId)
        {
            var meeting = db.ComiteeMeetings.Find(meetingId);
            if (meeting == null) return NotFound();

            var parameterIds = db.Fyp2MeetingMapping
                .Where(x => x.meetingID == meetingId)
                .Select(x => x.parameterID)
                .ToList();

            var allSubParams = db.Fyp2SubParameter
                .Where(s => parameterIds.Contains((int)s.parameterID))
                .ToList();

        

            var data = db.Fyp2EvaluationParameters
                .Where(p => parameterIds.Contains(p.id))
                .ToList()
                .Select(p => new
                {
                    p.id,
                    p.name,
                    p.percentage,

                    subParameters = allSubParams
                        .Where(s => s.parameterID == p.id)
                        .Select(s => new
                        {
                            s.id,
                            s.name,
                            s.percentage

                        })
                        .ToList()

                  
                })
                .ToList();

            return Ok(new
            {
                meeting.isGraded,
                parameters = data
            });
        }


        [HttpGet]
        [Route("final-score/{studentId}/{meetingId}/{sessionId}")]
        public IHttpActionResult CalculateFinalScore(
    int studentId,
    int taskId,
    int sessionId)
        {

            // 1️⃣ Fetch all evaluation marks for this student & meeting
            var marks = db.Fyp2StudentEvaluationMarks
                .Where(x =>
                    x.studentEnrollID == studentId &&
                    x.taskID == taskId &&
                    x.sessionID == sessionId)
                .ToList();

            if (!marks.Any())
                return BadRequest("No evaluation found");

            // 2️⃣ Group by Parameter
            var parameterScores = marks
                .GroupBy(x => x.parameterID)
                .Select(g =>
                {
                    var parameter = db.Fyp2EvaluationParameters
                        .First(p => p.id == g.Key);

                    decimal obtained = g.Sum(x => x.obtainedMarks ?? 0);
                    decimal max = g.Sum(x => x.maxMarks ?? 0);

                    decimal paramPercentage = (decimal)parameter.percentage;

                    // Weighted score
                    decimal weightedScore =
                        max == 0 ? 0 :
                        (obtained / max) * paramPercentage;

                    return new
                    {
                        ParameterId = g.Key,
                        WeightedScore = weightedScore,
                        ParameterPercentage = paramPercentage
                    };
                })
                .ToList();

            // 3️⃣ Final score
            decimal finalScore = parameterScores.Sum(x => x.WeightedScore);
            decimal totalPercentage = parameterScores.Sum(x => x.ParameterPercentage);

            // 4️⃣ Grade Logic
            string grade =
                finalScore >= 85 ? "A" :
                finalScore >= 75 ? "B+" :
                finalScore >= 65 ? "B" :
                finalScore >= 55 ? "C" : "F";

            return Ok(new Fyp2FinalEvaluationResultDto
            {
                StudentId = studentId,
                TotalObtained = System.Math.Round(finalScore, 2),
                TotalPercentage = totalPercentage,
                Grade = grade
            });

        }
        [HttpGet]
        [Route("available-criteria/{sessionId}")]
        public IHttpActionResult GetAvailableCriteria(int sessionId)
        {
            var criteria = db.Fyp2EvaluationParameters
                .Where(p => p.sessionID == sessionId)
                .Select(p => new
                {
                    p.id,
                    p.name,
                    p.percentage,

                    // optional: include sub-criteria if needed in UI
                    subParameters = db.Fyp2SubParameter
                        .Where(s => s.parameterID == p.id)
                        .Select(s => new
                        {
                            s.id,
                            s.name,
                            s.percentage
                        })
                        .ToList()
                })
                .ToList();

            if (!criteria.Any())
                return Ok(new List<object>());

            return Ok(criteria);
        }

        [HttpGet]
        [Route("getDataForUpdateMarks/{groupId}")]
        public IHttpActionResult GetSpecificGroupDetails(int groupId)
        {
            // 🔹 Define current session (adjust if dynamic)

            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name


            }).FirstOrDefault();
            var memberList = db.GroupMembers
                .Where(gm => gm.groupID == groupId)
                .Select(gm => new
                {
                    GroupId = groupId,

                    // Student Info
                    StudentID = gm.studentID,
                    StudentName = gm.Student.name,
                    gm.Student.currentCGPA,
                    gm.Student.gender,
                    sessionID = list.id,
                    // ✅ Enrollment ID (IMPORTANT)
                    EnrollmentID = db.Enrollments
                        .Where(e => e.studentID == gm.studentID && e.sessionID == list.id && e.subject == "FYP-2")
                        .Select(e => e.id)
                        .FirstOrDefault(),
                    Grade = db.Enrollments
                        .Where(e => e.studentID == gm.studentID && e.sessionID == list.id && e.subject == "FYP-2")
                        .Select(e => e.grade)
                        .FirstOrDefault(),
                        TaskId = db.Fyp2Task.Where(t => t.groupId == groupId && t.sessionID == list.id).Select(t => t.id).FirstOrDefault(),
                    // ✅ Technology Name (optimized)
                    Tech = db.Technologies
                        .Where(t => t.id == gm.Student.selectedTech)
                        .Select(t => t.name)
                        .FirstOrDefault()
                })
                .ToList();

            return Ok(memberList);
        }

        [HttpPost]
        [Route("update-evaluation-marks")]
        public IHttpActionResult UpdateEvaluationMarks(List<Fyp2UpdateEvaluationMarksDto> dtos)
        {
            foreach (var dto in dtos)
            {
                var record = db.Fyp2StudentEvaluationMarks.FirstOrDefault(x =>
                    x.studentEnrollID == dto.EnrollmentID &&
                    x.taskID == dto.taskID &&
                    x.sessionID == dto.SessionID &&
                    x.parameterID == dto.ParameterID &&
                    x.subParameterID == dto.SubParameterID &&
                    x.evaluatorID == dto.EvaluatorID
                );

                if (record != null)
                {
                    record.obtainedMarks = dto.ObtainedMarks;
                    record.maxMarks = dto.MaxMarks;
                    record.evaluatorID = dto.EvaluatorID;
                }
                else
                {
                    db.Fyp2StudentEvaluationMarks.Add(new Fyp2StudentEvaluationMarks
                    {
                        studentEnrollID = dto.EnrollmentID, // ✅ FIXED
                        taskID = dto.taskID,
                        sessionID = dto.SessionID,
                        parameterID = dto.ParameterID,
                        subParameterID = dto.SubParameterID,
                        obtainedMarks = dto.ObtainedMarks,
                        maxMarks = dto.MaxMarks,
                        evaluatorID = dto.EvaluatorID
                    });
                }
            }


            db.SaveChanges();

            return Ok(new
            {
                Message = "Marks saved successfully"
            });
        }

        [HttpGet]
        [Route("get-saved-marks/{parameterId}/{evaluatorId}")]
        public IHttpActionResult GetSavedMarks(int parameterId, string evaluatorId)
        {
            try
            {
                var currentSession = db.Sessions.OrderByDescending(s => s.id).FirstOrDefault();
                if (currentSession == null) return BadRequest("No active session");

                var marks = db.Fyp2StudentEvaluationMarks
                    .Where(m => m.sessionID == currentSession.id && 
                                m.parameterID == parameterId && 
                                m.evaluatorID == evaluatorId)
                    .Select(m => new
                    {
                        studentEnrollID = m.studentEnrollID,
                        subParameterID = m.subParameterID,
                        obtainedMarks = m.obtainedMarks,
                        maxMarks = m.maxMarks
                    })
                    .ToList();

                return Ok(marks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("get-all-saved-marks/{parameterId}")]
        public IHttpActionResult GetAllSavedMarks(int parameterId)
        {
            try
            {
                var currentSession = db.Sessions.OrderByDescending(s => s.id).FirstOrDefault();
                if (currentSession == null) return BadRequest("No active session");

                var marks = (from m in db.Fyp2StudentEvaluationMarks
                             where m.sessionID == currentSession.id && m.parameterID == parameterId
                             join u in db.Users on m.evaluatorID equals u.id into userGroup
                             from u in userGroup.DefaultIfEmpty()
                             select new
                             {
                                 studentEnrollID = m.studentEnrollID,
                                 subParameterID = m.subParameterID,
                                 obtainedMarks = m.obtainedMarks,
                                 maxMarks = m.maxMarks,
                                 evaluatorID = m.evaluatorID,
                                 evaluatorRole = u != null ? u.role : "Unknown"
                             }).ToList();

                return Ok(marks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("groups/{groupId}")]
        public IHttpActionResult GetGroup(int groupId)
        {
            try
            {
                // =====================================
                // CURRENT SESSION
                // =====================================

                var currentSession = db.Sessions
                    .OrderByDescending(s => s.id)
                    .FirstOrDefault();

                if (currentSession == null)
                    return BadRequest("No active session found");

                // =====================================
                // GET GROUP
                // =====================================

                var group = db.ProjectGroups

                    // ✅ SPECIFIC GROUP
                    .Where(g => g.id == groupId)

                    // ✅ ONLY FYP-2 GROUP
                    .Where(g =>
                        db.GroupMembers.Any(gm =>
                            gm.groupID == g.id &&
                            db.Enrollments.Any(e =>
                                e.studentID == gm.studentID &&
                                e.sessionID == currentSession.id &&
                                e.subject == "FYP-2"
                            )
                        )
                    )

                    // =====================================
                    // SELECT
                    // =====================================

                    .Select(g => new
                    {
                        id = g.id,

                        name = "Group " + g.id,

                        projectName = g.OfferedProject != null && g.OfferedProject.Project != null ? g.OfferedProject.Project.title : "No Project Assigned",
                        
                        projectDescription = g.OfferedProject != null && g.OfferedProject.Project != null ? g.OfferedProject.Project.title : "",

                        // =====================================
                        // FINAL TASK
                        // =====================================

                        finalTask = db.Fyp2Task
                            .Where(t =>
                                t.groupId == g.id &&
                                t.sessionID == currentSession.id &&
                                t.taskTitle == "Final Task"
                            )
                            .Select(t => t.taskDescription)
                            .FirstOrDefault() ?? "",

                        midTask = db.Fyp2Task
                            .Where(t =>
                                t.groupId == g.id &&
                                t.sessionID == currentSession.id &&
                                (t.taskTitle == "MidTask" || t.taskTitle == "Midtask")
                            )
                            .Select(t => t.taskDescription)
                            .FirstOrDefault() ?? "",

                        // =====================================
                        // LATEST MEETING DATE
                        // =====================================

                        meetingDate = db.GroupSchedules
                            .Where(gs =>
                                gs.groupID == g.id &&
                                gs.type == "FYP-2"
                            )
                            .OrderByDescending(gs => gs.meetingDate)
                            .Select(gs => gs.meetingDate)
                            .FirstOrDefault(),

                        // =====================================
                        // LATEST REMARKS
                        // =====================================

                        remarks = db.Fyp2StudentEvaluationRemarks

                            .Where(r =>
                                r.sessionID == currentSession.id &&

                                db.GroupMembers
                                    .Where(gm => gm.groupID == g.id)
                                    .Select(gm => gm.studentID)
                                    .Contains(

                                        db.Enrollments
                                            .Where(e => e.id == r.studentEnrollID)
                                            .Select(e => e.studentID)
                                            .FirstOrDefault()
                                    )
                            )

                            .OrderByDescending(r => r.createdAt)

                            .Select(r => r.remarks)

                            .FirstOrDefault()

                            ?? "No remarks available",

                        // =====================================
                        // MEMBERS
                        // =====================================

                        members = g.GroupMembers
                            .Select(m => new
                            {
                                regNum = m.Student.regNum,

                                name = m.Student.name,

                                cgpa = m.Student.currentCGPA,

                                gender = m.Student.gender,

                                section = m.Student.studentSection
                            })
                            .ToList()
                    })

                    .FirstOrDefault();

                // =====================================
                // NOT FOUND
                // =====================================

                if (group == null)
                    return NotFound();

                // =====================================
                // RETURN
                // =====================================

                return Ok(group);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("student-progress/{studentId}/{type}")]
        public IHttpActionResult GetStudentProgress(string studentId, string type)
        {
            try
            {
                var currentSession = db.Sessions
                    .OrderByDescending(s => s.id)
                    .FirstOrDefault();

                if (currentSession == null)
                    return BadRequest("No active session found");

                // ============================
                // STUDENT
                // ============================
                var student = db.Students
                    .FirstOrDefault(s => s.regNum == studentId);

                if (student == null)
                    return NotFound();

                // ============================
                // ENROLLMENT
                // ============================
                var enrollment = db.Enrollments
                    .FirstOrDefault(e =>
                        e.studentID == studentId &&
                        e.sessionID == currentSession.id &&
                        e.subject == type);

                if (enrollment == null)
                    return BadRequest("Student not enrolled");

                // ============================
                // GROUP MEMBER
                // ============================
                var groupMember = db.GroupMembers
                    .FirstOrDefault(g => g.studentID == studentId);

                if (groupMember == null)
                    return BadRequest("Group not found");

                int groupId = (int)groupMember.groupID;

                // ============================
                // SUPERVISOR ATTENDANCE
                // ============================

                var today = DateTime.Today;

                var supervisorMeetings = db.SuperVisorMeetings
                    .Count(m =>
                        m.sessionId == currentSession.id &&
                        m.date.HasValue &&
                        m.date <= today &&
                        (
                            m.groupID == groupId ||
                            m.memberId == studentId
                        ));

                // Student Attendance Count
                var supervisorAttend = db.SupervisorAttendances
                    .Count(a =>
                        a.memberID == groupMember.id &&
                        a.isAttend == true);

                // ============================
                // COMMITTEE ATTENDANCE
                // ============================

                var committeeMeetings = db.GroupSchedules
                    .Count(gs =>
                        gs.groupID == groupId &&
                        gs.type == type);

                var committeeAttend = db.GroupSchedules
                    .Count(gs =>
                        gs.groupID == groupId &&
                        gs.type == type &&
                        gs.isAttend == 1);

                // ============================
                // SUPERVISOR REMARKS
                // ============================

                var supervisorGroupRemarks = db.SupervisorRemarks
                    .Where(r => r.GroupID == groupId)
                    .OrderByDescending(r => r.CreatedAt)
                    .ToList()
                    .Select(r => new { 
                        Remarks = r.Remarks, 
                        Date = r.CreatedAt, 
                        Evaluator = "Supervisor", 
                        Meeting = "Group Review" 
                    })
                    .Cast<object>()
                    .ToList();

                var supervisorRemarks = db.SupervisorRemarks
                   .Where(r => r.GroupID == groupId && r.StudentEnrollID == enrollment.id)
                   .OrderByDescending(r => r.CreatedAt)
                   .ToList()
                   .Select(r => new { 
                       Remarks = r.Remarks, 
                       Date = r.CreatedAt, 
                       Evaluator = "Supervisor", 
                       Meeting = "Individual Review" 
                   })
                   .Cast<object>()
                   .ToList();

                // ============================
                // COMMITTEE REMARKS
                // ============================

                List<object> committeeRemarks = new List<object>();

                // Get CommitteeHead IDs to exclude their remarks from the general committee section
                var headIds = db.Users
                    .Where(u => u.role == "Committee")
                    .Select(u => u.id)
                    .ToList();

                if (type == "FYP-1")
                {
                    committeeRemarks = db.FypStudentEvaluationRemarks
                        .Where(r => r.studentEnrollID == enrollment.id
                               && r.sessionID == currentSession.id
                               && !headIds.Contains(r.evaluatorID))
                        .OrderByDescending(r => r.createdAt)
                        .ToList()
                        .Select(r => new {
                            Remarks = r.remarks,
                            Date = r.createdAt,
                            Evaluator = db.Users.Where(u => u.id == r.evaluatorID).Select(u => u.name).FirstOrDefault() ?? r.evaluatorID,
                            Meeting = db.ComiteeMeetings.Where(m => m.id == r.meetingID).Select(m => m.title).FirstOrDefault() ?? "Committee Meeting"
                        })
                        .Cast<object>()
                        .ToList();
                }
                else
                {
                    committeeRemarks = db.Fyp2StudentEvaluationRemarks
                        .Where(r => r.studentEnrollID == enrollment.id
                               && r.sessionID == currentSession.id
                               && !headIds.Contains(r.evaluatorID))
                        .OrderByDescending(r => r.createdAt)
                        .ToList()
                        .Select(r => new {
                            Remarks = r.remarks,
                            Date = r.createdAt,
                            Evaluator = db.Users.Where(u => u.id == r.evaluatorID).Select(u => u.name).FirstOrDefault() ?? r.evaluatorID,
                            Meeting = db.Fyp2Task.Where(t => t.id == r.taskID).Select(t => t.taskDescription).FirstOrDefault() ?? "Committee Meeting"
                        })
                        .Cast<object>()
                        .ToList();
                }

                // ============================
                // COMMITTEE HEAD REMARKS
                // ============================
                // These are remarks saved by users with the Director/CommitteeHead role
                var directorRoleIds = db.Users
                    .Where(u => u.role == "CommitteeHead")
                    .Select(u => u.id)
                    .ToList();

                List<object> committeeHeadRemarks;
                if (type == "FYP-1")
                {
                    committeeHeadRemarks = db.FypStudentEvaluationRemarks
                        .Where(r => r.studentEnrollID == enrollment.id
                               && r.sessionID == currentSession.id
                               && directorRoleIds.Contains(r.evaluatorID))
                        .OrderByDescending(r => r.createdAt)
                        .ToList()
                        .Select(r => (object)new {
                            Remarks = r.remarks,
                            Date = r.createdAt,
                            Evaluator = db.Users.Where(u => u.id == r.evaluatorID).Select(u => u.name).FirstOrDefault() ?? r.evaluatorID,
                            Meeting = db.ComiteeMeetings.Where(m => m.id == r.meetingID).Select(m => m.title).FirstOrDefault() ?? "Committee Meeting"
                        })
                        .ToList();
                }
                else
                {
                    committeeHeadRemarks = db.Fyp2StudentEvaluationRemarks
                        .Where(r => r.studentEnrollID == enrollment.id
                               && r.sessionID == currentSession.id
                               && directorRoleIds.Contains(r.evaluatorID))
                        .OrderByDescending(r => r.createdAt)
                        .ToList()
                        .Select(r => (object)new {
                            Remarks = r.remarks,
                            Date = r.createdAt,
                            Evaluator = db.Users.Where(u => u.id == r.evaluatorID).Select(u => u.name).FirstOrDefault() ?? r.evaluatorID,
                            Meeting = "Committee Head Review"
                        })
                        .ToList();
                }

                // ============================
                // TASK PROGRESS
                // ============================
                int taskProgress = 0;

                var studentTasks = db.Tasks
                    .Where(t =>
                        t.groupID == groupId &&
                        (
                            t.studentID == null ||
                            t.studentID == studentId
                        ))
                    .ToList();

                if (studentTasks.Count > 0)
                {
                    double totalScoreSum = 0;
                    foreach (var t in studentTasks)
                    {
                        var eval = db.TaskEvaluations.FirstOrDefault(te => te.taskID == t.id);
                        if (eval != null)
                        {
                            totalScoreSum += eval.score ?? 0;
                        }
                    }
                    taskProgress = (int)Math.Round(totalScoreSum / studentTasks.Count);
                }

                // ============================
                // RESPONSE
                // ============================

                return Ok(new
                {
                    studentName = student.name,
                    groupName = "Group " + groupId,

                    attendance = new
                    {
                        supervisor = new
                        {
                            attended = supervisorAttend,
                            total = supervisorMeetings
                        },

                        committee = new
                        {
                            attended = committeeAttend,
                            total = committeeMeetings
                        }
                    },

                    committeeHeadRemarks,
                    supervisorGroupRemarks,
                    supervisorRemarks,
                    committeeRemarks,
                    taskProgress
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpPost]
        [Route("assign-task")]
        public IHttpActionResult AssignTask(AssignTaskDto model)
        {
            try
            {
                if (model == null || string.IsNullOrWhiteSpace(model.taskDescription))
                    return BadRequest("Invalid task");

                var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new {
                    e.id,
                    e.name
                }).FirstOrDefault();

                string title = string.IsNullOrWhiteSpace(model.taskTitle) ? "Final Task" : model.taskTitle;

                // 🔍 Check if task already exists
                var existingTask = db.Fyp2Task
                    .FirstOrDefault(t => t.groupId == model.groupId && t.sessionID == list.id && t.taskTitle == title);

                if (existingTask != null)
                {
                    // 🔁 UPDATE
                    existingTask.taskDescription = model.taskDescription;
                    existingTask.assignedDate = DateTime.Now;
                }
                else
                {
                    // ➕ INSERT
                    var newTask = new Fyp2Task
                    {
                        groupId = model.groupId,
                        taskDescription = model.taskDescription,
                        taskTitle = title,
                        assignedDate = DateTime.Now,
                        sessionID = list.id
                    };

                    db.Fyp2Task.Add(newTask);
                }

                db.SaveChanges();

                return Ok(new { message = "Task saved successfully" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("Getcriteria/{sessionId}")]
        public IHttpActionResult GetCriteriaBySession(int sessionId)
        {
            var data = db.Fyp2EvaluationParameters
                .Where(p => p.sessionID == sessionId)
                .Select(p => new
                {
                    id = p.id,
                    name = p.name,
                    percentage = p.percentage ?? 0,
                   
                    
                    subParameters = p.Fyp2SubParameter
                        .Select(s => new
                        {
                            id = s.id,
                            name = s.name,
                            percentage = s.percentage ?? 0
                        })
                        .ToList()
                })
                .ToList();

            return Ok(data);
        }

        [HttpPost]
        [Route("Editcriteria/{sessionId}")]
        public IHttpActionResult UpdateCriteria(int sessionId, List<EvaluationCriteriaDto> model)
        {
            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    foreach (var p in model)
                    {
                        var param = db.Fyp2EvaluationParameters
                            .Include("Fyp2SubParameter")
                            .FirstOrDefault(x => x.id == p.id && x.sessionID == sessionId);

                        if (param == null) continue;

                        param.name = p.name;
                        param.percentage = p.percentage;


                      

                        // 🔴 Remove old sub parameters
                        db.Fyp2SubParameter.RemoveRange(param.Fyp2SubParameter);

                        // ✅ Add updated sub parameters
                        if (p.subParameters != null)
                        {
                            foreach (var sub in p.subParameters)
                            {
                                db.Fyp2SubParameter.Add(new Fyp2SubParameter
                                {
                                    parameterID = param.id,
                                    name = sub.name,
                                    percentage = sub.percentage
                                });
                            }
                        }
                    }

                    db.SaveChanges();
                    transaction.Commit();
                    return Ok("Criteria updated successfully");
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    return InternalServerError(ex);
                }
            }
        }
        [HttpPost]
        [Route("save-criteria")]
        public IHttpActionResult SaveCriteria(SaveCriteriaDto model)
        {
            if (model == null || model.parameters == null || !model.parameters.Any())
                return BadRequest("Invalid criteria data");

            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    foreach (var p in model.parameters)
                    {
                        // MAIN PARAMETER
                        var param = new Fyp2EvaluationParameters
                        {
                            name = p.name,
                            percentage = p.percentage,
                            sessionID = model.sessionID
                        };

                        db.Fyp2EvaluationParameters.Add(param);
                        db.SaveChanges(); // get param.id

                  

                        // SUB PARAMETERS
                        if (p.subParameters != null)
                        {
                            foreach (var sub in p.subParameters)
                            {
                                db.Fyp2SubParameter.Add(new Fyp2SubParameter
                                {
                                    parameterID = param.id,
                                    name = sub.name,
                                    percentage = sub.percentage
                                });
                            }
                        }
                    }

                    db.SaveChanges();
                    transaction.Commit();

                    return Ok(new { message = "Criteria saved successfully" });
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    return InternalServerError(ex);
                }
            }
        }
        public class AssignTaskDto
        {
            public int groupId { get; set; }
            public string taskDescription { get; set; }
            public string taskTitle { get; set; }
        }
        public class EvaluationParameterDto
        {
            public int ParameterID { get; set; }
            public string ParameterName { get; set; }
            public decimal Percentage { get; set; }
            public bool IsGraded { get; set; }
        }
        public class EvaluationCriteriaDto
        {
            public int id { get; set; } // 0 for insert
            public string name { get; set; }
            public int percentage { get; set; }
            public bool allowEvaluation { get; set; }
            public List<string> evaluators { get; set; }
            public List<SubParameterDto> subParameters { get; set; }
        }

        public class SubCriteriaDto
        {
            public int id { get; set; }
            public string name { get; set; }
            public int? percentage { get; set; }
        }
        public class SaveCriteriaDto
        {
            public int sessionID { get; set; }
            public List<ParameterDto> parameters { get; set; }
        }

        public class ParameterDto
        {
            public string name { get; set; }
            public int percentage { get; set; }
            public bool allowEvaluation { get; set; }

            public List<string> evaluators { get; set; } // regNo or ID
            public List<SubParameterDto> subParameters { get; set; }
        }

        public class SubParameterDto
        {
            public string name { get; set; }
            public int percentage { get; set; }
        }

        public class Fyp2UpdateEvaluationMarksDto
        {
            public int EnrollmentID { get; set; }   // ✅ FIXED
            public int taskID { get; set; }
            public int ParameterID { get; set; }
            public int SubParameterID { get; set; }
            public string EvaluatorID { get; set; }
            public decimal ObtainedMarks { get; set; }
            public decimal MaxMarks { get; set; }
            public int SessionID { get; set; }
        }
        public class Fyp2FinalEvaluationResultDto
        {
            public int StudentId { get; set; }
            public decimal TotalObtained { get; set; }
            public decimal TotalPercentage { get; set; }
            public string Grade { get; set; }
        }

        public class StudentEvaluationRemarkDto
        {
            public int StudentEnrollID { get; set; }
            public int taskID { get; set; }
            public string EvaluatorID { get; set; }
            public int SessionID { get; set; }
            public string Remarks { get; set; }
        }

        public class Fyp2AssignParametersDto
        {
            public int MeetingId { get; set; }
            public List<int> ParameterIds { get; set; }
        }
        [HttpPost]
        [Route("calculate-final-fyp2")]
        public IHttpActionResult CalculateFinalFyp2([FromUri] bool includeSupervisorScore = false)
        {
            var currentSession = db.Sessions
                .OrderByDescending(s => s.id)
                .FirstOrDefault();

            if (currentSession == null)
                return BadRequest("No session found");

            var marks = db.Fyp2StudentEvaluationMarks
                .Where(m => m.sessionID == currentSession.id)
                .ToList();

            var result = marks
                .GroupBy(m => m.studentEnrollID)
                .Select(studentGroup =>
                {
                    decimal finalScore = 0;

                    // ============================
                    // GROUP BY PARAMETER
                    // ============================

                    var parameterGroups = studentGroup
                        .GroupBy(x => x.parameterID);

                    foreach (var paramGroup in parameterGroups)
                    {
                        var parameter = db.Fyp2EvaluationParameters
                            .FirstOrDefault(p => p.id == paramGroup.Key);

                        if (parameter == null)
                            continue;

                        decimal parameterTotal = 0;

                        // ============================
                        // GROUP BY SUB PARAMETER
                        // ============================

                        var subGroups = paramGroup
                            .GroupBy(x => x.subParameterID);

                        foreach (var subGroup in subGroups)
                        {
                            var subParam = db.Fyp2SubParameter
                                .FirstOrDefault(s => s.id == subGroup.Key);

                            // Average percentage obtained

                            decimal avgPercentage = subGroup
                                .Average(x => (x.maxMarks ?? 0) == 0 ? 0m : ((x.obtainedMarks ?? 0m) / (x.maxMarks ?? 1m)) * 100m);

                            // ============================
                            // APPLY SUB PARAMETER WEIGHT
                            // ============================

                            if (subParam != null)
                            {
                                parameterTotal +=
                                    (avgPercentage * (decimal)subParam.percentage) / 100m;
                            }
                            else
                            {
                                parameterTotal += avgPercentage;
                            }
                        }

                        // ============================
                        // APPLY PARAMETER WEIGHT
                        // ============================

                        finalScore +=
                            (parameterTotal * (decimal)parameter.percentage) / 100m;
                    }

                    // 🔹 Incorporate Supervisor Score if enabled (80% Director, 20% Supervisor)
                    if (includeSupervisorScore)
                    {
                        var enrollment = db.Enrollments.FirstOrDefault(e => e.id == studentGroup.Key);
                        if (enrollment != null)
                        {
                            var studentId = enrollment.studentID;
                            var groupMember = db.GroupMembers.FirstOrDefault(gm => gm.studentID == studentId);
                            if (groupMember != null)
                            {
                                int groupId = (int)groupMember.groupID;
                                var tasks = db.Tasks.Where(t => t.groupID == groupId && (t.studentID == null || t.studentID == studentId)).ToList();
                                if (tasks.Count > 0)
                                {
                                    double totalTaskScore = 0;
                                    int evaluatedTasksCount = 0;
                                    foreach (var t in tasks)
                                    {
                                        var eval = db.TaskEvaluations.FirstOrDefault(te => te.taskID == t.id);
                                        if (eval != null && eval.score != null)
                                        {
                                            totalTaskScore += eval.score.Value;
                                            evaluatedTasksCount++;
                                        }
                                    }
                                    if (evaluatedTasksCount > 0)
                                    {
                                        decimal avgSupScore = (decimal)(totalTaskScore / evaluatedTasksCount);
                                        finalScore = (finalScore * 0.8m) + (avgSupScore * 0.2m);
                                    }
                                }
                            }
                        }
                    }

                    var roundedScore = Math.Round(finalScore, 2);

                    return new
                    {
                        EnrollmentID = studentGroup.Key,
                        SessionID = currentSession.id,
                        FinalScore = roundedScore,
                        Grade = GetGrade((double)roundedScore)
                    };
                })
                .ToList();

            // ============================
            // SAVE GRADE INTO ENROLLMENT
            // ============================

            foreach (var r in result)
            {
                var enrollment = db.Enrollments
                    .FirstOrDefault(e =>
                        e.id == r.EnrollmentID &&
                        e.subject == "FYP-2");

                if (enrollment != null)
                {
                    enrollment.grade = r.Grade;
                }
            }

            db.SaveChanges();

            return Ok(result);
        }

        public class SaveFinalGradeDto
        {
            public int EnrollmentID { get; set; }
            public string FinalGrade { get; set; }
            public decimal? FinalScore { get; set; }
            public int SessionID { get; set; }
            public string EvaluatorID { get; set; }
        }

        [HttpPost]
        [Route("save-final-grades")]
        public IHttpActionResult SaveFinalGrades(List<SaveFinalGradeDto> dtos)
        {
            if (dtos == null || !dtos.Any())
                return BadRequest("No grades provided.");

            foreach (var dto in dtos)
            {
                var enrollment = db.Enrollments.Find(dto.EnrollmentID);
                if (enrollment != null)
                {
                    enrollment.grade = dto.FinalGrade;
                }
            }

            db.SaveChanges();
            return Ok(new { message = "Final grades saved successfully" });
        }

        private string GetGrade(double score)
        {
            if (score >= 90) return "A+";
            if (score >= 85) return "A";
            if (score >= 80) return "A-";
            if (score >= 75) return "B+";
            if (score >= 71) return "B";
            if (score >= 68) return "B-";
            if (score >= 64) return "C+";
            if (score >= 61) return "C";
            if (score >= 58) return "C-";
            if (score >= 54) return "D+";
            if (score >= 50) return "D";
            return "F";
        }

        

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }
}
