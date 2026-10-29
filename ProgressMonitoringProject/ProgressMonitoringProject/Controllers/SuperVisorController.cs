using Microsoft.AspNetCore.Mvc;
using ProgressMonitoringProject.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Routing;
using HttpGetAttribute = System.Web.Http.HttpGetAttribute;
using HttpPostAttribute = Microsoft.AspNetCore.Mvc.HttpPostAttribute;
using System.Net.Http;
using RouteAttribute = System.Web.Http.RouteAttribute;

namespace ProgressMonitoringProject.Controllers
{
    [System.Web.Http.RoutePrefix("api/supervisor")]
    public class SuperVisorController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet]
        [Route("{supervisorId}")]
        public async Task<List<object>> GetSupervisorFyp1Groups(string supervisorId)
        {
            var flatResult =
                await (
                    from pg in db.ProjectGroups

                    join op in db.OfferedProjects
                        on pg.projectID equals op.id

                    join s in db.Sessions
                        on op.sessionID equals s.id

                    join p in db.Projects
                        on op.projectID equals p.id

                    join gm in db.GroupMembers
                        on pg.id equals gm.groupID

                    join st in db.Students
                        on gm.studentID equals st.regNum

                    join tech in db.Technologies
                        on st.selectedTech equals tech.id

                    where pg.supervisorID == supervisorId
                          && s.name.Contains("FALL25")   // or exact session like "Fall25"

                    select new
                    {
                        GroupId = pg.id,
                        GroupName = "Group " + pg.id,

                        ProjectTitle = p.title,

                        Member = new
                        {
                            StudentName = st.name,
                            Technology = tech.name,
                            CGPA = st.currentCGPA
                        }
                    }
                ).ToListAsync();

            // Group members under each group (UI-friendly)
            var groupedResult =
                flatResult
                    .GroupBy(x => new { x.GroupId, x.GroupName, x.ProjectTitle })
                    .Select(g => new
                    {
                        g.Key.GroupId,
                        g.Key.GroupName,
                        ProjectTitle = g.Key.ProjectTitle,
                        Members = g.Select(x => x.Member).ToList()
                    })
                    .ToList<object>();

            return groupedResult;
        }
        private int CalculateGroupProgress_InMemory(List<int> taskIds)
        {
            if (taskIds == null || taskIds.Count == 0)
                return 0;

            var evaluations = db.TaskEvaluations
                .Where(te => taskIds.Contains((int)te.taskID) && te.score != null)
                .Select(te => te.score.Value)
                .ToList();

            if (evaluations.Count == 0)
                return 0;

            double avgScore = evaluations.Average();
            return (int)Math.Round(avgScore);
        }
        [HttpGet]
        [Route("getAllGroups/{selectedFYP}/{supervisorId}")]
        public IHttpActionResult GetAllTech(string selectedFYP, string supervisorId)
        {
            try
            {
                // 1️⃣ Get enrolled students
                var enrolledStudents = db.Enrollments
                    .Where(x => x.subject == selectedFYP)
                    .Select(s => s.studentID)
                    .Distinct()
                    .ToList();

                // 2️⃣ Fetch groups + required data (NO custom method here)
                var groupsData = db.ProjectGroups
                    .Where(g =>
                        enrolledStudents.Contains(g.createdBy) &&
                        g.supervisorID == supervisorId
                    )
                    .Select(g => new
                    {
                        GroupId = g.id,
                        groupName = g.id,
                        projectTitle = g.OfferedProject.Project.title,

                        supervisor = db.Users
                            .Where(u => u.id == g.supervisorID)
                            .Select(s => s.name)
                            .FirstOrDefault(),

                        members = g.GroupMembers
                            .Select(m => new
                            {
                                studentRegNum = m.Student.regNum,
                                studentName = m.Student.name,
                                Cgpa = m.Student.currentCGPA
                            })
                            .ToList(),

                        // fetch task IDs only
                        TaskIds = db.Tasks
                            .Where(t => t.groupID == g.id)
                            .Select(t => t.id)
                            .ToList()
                    })
                    .ToList(); // ✅ SQL executes here

                // 3️⃣ Calculate progress IN MEMORY
                var result = groupsData.Select(g => new
                {
                    g.groupName,
                    g.projectTitle,
                    g.supervisor,
                    g.members,

                    progress = CalculateGroupProgress_InMemory(g.TaskIds)
                })
                .ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("studentAttendance")]
        public IHttpActionResult SaveAttendance(AttendanceDto model)
        {
            if (model == null || model.Attendance == null)
                return BadRequest("Invalid data");

            foreach (var item in model.Attendance)
            {
                // 🔍 Check if record already exists (Lambda)
                var existing = db.SupervisorAttendances
                    .FirstOrDefault(a =>
                        a.meetingID == model.MeetingId &&
                        a.memberID == item.memberId);

                if (existing != null)
                {
                    // ✏️ Update existing record
                    existing.isAttend = item.IsPresent;
                }
                else
                {
                    // ➕ Insert new record
                    var newAttendance = new SupervisorAttendance
                    {
                        meetingID = model.MeetingId,
                        memberID = item.memberId,
                        attendanceDate = DateTime.Now,
                        isAttend = item.IsPresent
                    };

                    db.SupervisorAttendances.Add(newAttendance);
                }
            }

            db.SaveChanges();

            return Ok(new { message = "Attendance saved successfully" });
        }


        [HttpGet]
        [Route("get-group-members-attendance/{groupId}")]
        public IHttpActionResult GetGroupMembersAttendance(int groupId)
        {
            var members = db.GroupMembers
                .Where(m => m.groupID == groupId)
                .Select(m => new
                {
                    id = m.id,
                    name = m.Student.name,

                    attendancePercentage =
                        db.SupervisorAttendances
                            .Where(a => a.memberID == m.id)
                            .Count(a => a.isAttend == true) * 100 /
                        (db.SupervisorAttendances
                            .Count(a => a.memberID == m.id) == 0
                            ? 1
                            : db.SupervisorAttendances
                                .Count(a => a.memberID == m.id))
                })
                .ToList();

            return Ok(members);
        }
        [HttpGet]
        [Route("GetGroupStudents/{groupId}")]
        public IHttpActionResult getGroupStudents(int groupId)
        {
            var students = db.GroupMembers.Where(gm => gm.groupID == groupId)
                .Select(gm => new
                {
                    StudentName = gm.Student.name,
                    RegNum = gm.Student.regNum,
                    Cgpa = gm.Student.currentCGPA
                })
                .ToList();

            return Ok(students);
        }

       
        [HttpPost]
        [Route("update-task-status")]
        public IHttpActionResult UpdateTaskStatus(UpdateTaskStatusDto model)
        {
            try
            {
                var task = db.Tasks.FirstOrDefault(t => t.id == model.TaskId);

                if (task == null)
                    return NotFound();

                task.taskStatus = model.Status;
                db.SaveChanges();

                return Ok("Updated");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        public class UpdateTaskStatusDto
        {
            public int TaskId { get; set; }
            public string Status { get; set; }
        }

        [HttpGet]
        [Route("supervisorMeetings/{type}")]
        public IHttpActionResult GetTodayMeetings(string type)
        {

            var result = db.GroupSchedules
                .Where(mq => mq.type == type)
                .OrderBy(mq => mq.estimatedTime) // <-- order by time
                .Select(mq => new
                {
                    scheduleId = mq.id,
                    id = mq.comiteeMeetingID,
                    GroupIDs = mq.groupID,
                    MeetingTitle = mq.ComiteeMeeting.title,
                    MeetingDate = mq.meetingDate,
                    MeetingTime = mq.estimatedTime, // this will now be in order
                    Status = mq.Status,
                    Type = mq.type
                })
                .ToList();

            return Ok(result);
        }
        [HttpGet]
        [Route("getAllTasks/{supervisorId}/{fypType}")]
        public IHttpActionResult GetAllTasks(string supervisorId, string fypType)
        {
            try
            {
                // 🔹 Current session
                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                // 🔹 Tasks assigned by supervisor for this session + FYP
                var tasks = (
                    from t in db.Tasks
                    join pg in db.ProjectGroups on t.groupID equals pg.id
                    join gm in db.GroupMembers on pg.id equals gm.groupID
                    join e in db.Enrollments on gm.studentID equals e.studentID
                    where
                        t.assignedBy == supervisorId &&
                        pg.createdSession == currentSessionId &&
                        e.subject == fypType &&
                        e.sessionID == currentSessionId
                    select new
                    {
                        // 🔹 TASK
                        Id = t.id,
                        Title = t.title,
                        Description = t.taskDescription,
                        DueDate = t.dueDate,
                        TaskStatus = t.taskStatus,
                        IsPptRequired = t.isPptRequired,
                        SubmissionFilePath = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => te.submissionFilePath).FirstOrDefault(),
                        Score = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => (int?)te.score).FirstOrDefault(),
                        Remarks = db.TaskEvaluations.Where(te => te.taskID == t.id).Select(te => te.taskRemarks).FirstOrDefault(),

                        // 🔹 GROUP
                        GroupId = t.groupID,

                        // 🔹 INDIVIDUAL (NULL = GROUP TASK)
                        StudentId = t.studentID,
                        StudentName = t.studentID != null
                            ? db.Students
                                .Where(s => s.regNum == t.studentID)
                                .Select(s => s.name)
                                .FirstOrDefault()
                            : null
                    }
                )
                .Distinct()
                .OrderBy(t => t.DueDate)
                .ToList();

                return Ok(tasks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("GetSupervisorGroups/{supervisorId}/{fypType}")]
        public IHttpActionResult GetSupervisorGroups(string supervisorId, string fypType)
        {
            try
            {
                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                // Only return groups where at least one member is enrolled in the selected fypType
                var groups = db.ProjectGroups
                    .Where(pg => pg.supervisorID == supervisorId && pg.createdSession == currentSessionId)
                    .Where(pg => db.GroupMembers
                        .Any(gm => gm.groupID == pg.id && db.Enrollments
                            .Any(e => e.studentID == gm.studentID && e.sessionID == currentSessionId && e.subject == fypType)
                        )
                    )
                    .Select(pg => new
                    {
                        GroupId = pg.id,
                        ProjectId = pg.projectID,
                        SupervisorId = pg.supervisorID,
                        IsFinalized = pg.isFinalized == 1
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
        [Route("getSupervisorMeetings/{supervisorId}/{selectedFYP}")]
        public IHttpActionResult GetSupervisorMeetings(
    string supervisorId,
    string selectedFYP   // FYP-1 or FYP-2
)
        {
            try
            {
                // 🔹 Get current session
                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                // 🔹 Get supervisor groups for selected FYP & current session
                var supervisorGroupIds = db.ProjectGroups
                    .Where(pg =>
                        pg.supervisorID == supervisorId &&
                        pg.createdSession == currentSessionId
                    )
                    .Where(pg => db.GroupMembers
                        .Any(gm => gm.groupID == pg.id && db.Enrollments
                            .Any(e => e.studentID == gm.studentID && e.sessionID == currentSessionId && e.subject == selectedFYP)
                        )
                    )
                    .Select(pg => pg.id)
                    .Distinct()
                    .ToList();

                // 🔹 Fetch meetings
                var meetings = db.SuperVisorMeetings
                    .Where(m =>
                        supervisorGroupIds.Contains((int)m.groupID)
                    )
                    .OrderBy(m => m.date)
                    .ThenBy(m => m.time)
                    .Select(m => new SupervisorMeetingDto
                    {
                        Id = m.id,
                        Date = m.date,
                        Time = m.time,
                        Day = m.day,
                        Venue = m.venue,
                        CreatedBy = m.createdBy,
                        GroupId = m.groupID,
                        memberId = m.memberId,
                        IsRecurring = (bool)m.isRecurring,
                        EndDate = m.EndDate,
                        Title = m.title,
                        Description = m.description,
                        PptRequired = m.pptRequired,

                        RecurringDays = db.RecurringMeetingDays
                            .Where(r => r.meetingID == m.id)
                            .Select(r => r.meetingDay)
                            .ToList()
                    })
                    .ToList();

                return Ok(meetings);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("group-meetings/{groupId}")]
        public IHttpActionResult GetGroupSupervisorMeetings(int groupId)
        {
            try
            {
                var meetings = db.SuperVisorMeetings
                    .Where(m => m.groupID == groupId)
                    .OrderBy(m => m.date)
                    .ThenBy(m => m.time)
                    .Select(m => new SupervisorMeetingDto
                    {
                        Id = m.id,
                        Date = m.date,
                        Time = m.time,
                        Day = m.day,
                        Venue = m.venue,
                        CreatedBy = m.createdBy,
                        GroupId = m.groupID,
                        memberId = m.memberId,
                        IsRecurring = (bool)m.isRecurring,
                        EndDate = m.EndDate,
                        Title = m.title,
                        Description = m.description,
                        PptRequired = m.pptRequired
                    })
                    .ToList();

                return Ok(meetings);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("get-supervisor-remarks/{studentEnrollID}/{supervisorID}/{meetingID}")]
        public IHttpActionResult GetSupervisorRemarks(
     int studentEnrollID,
     string supervisorID,
     int meetingID)
        {
            try
            {
                var remarks = db.SupervisorRemarks
                    .Where(r =>
                        r.StudentEnrollID == studentEnrollID &&
                        r.SupervisorID == supervisorID 
                    )
                    .OrderByDescending(r => r.UpdatedAt ?? r.CreatedAt)
                    .Select(r => new
                    {
                        r.Id,
                        r.GroupID,
                        r.Remarks,
                        r.CreatedAt,
                        r.UpdatedAt
                    })
                    .FirstOrDefault();

                return Ok(remarks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("get-group-remarks/{groupID}/{supervisorID}/{meetingID}")]
        public IHttpActionResult GetGroupRemarks(
    int groupID,
    string supervisorID,
    int meetingID)
        {
            try
            {
                var remarks = db.SupervisorRemarks
                    .Where(r =>
                        r.GroupID == groupID &&
                        r.SupervisorID == supervisorID &&
                        r.MeetingID == meetingID &&
                        r.StudentEnrollID == null // 🔥 GROUP ONLY
                    )
                    .OrderByDescending(r => r.UpdatedAt ?? r.CreatedAt)
                    .Select(r => new
                    {
                        r.Id,
                        r.Remarks,
                        r.CreatedAt,
                        r.UpdatedAt
                    })
                    .FirstOrDefault();

                return Ok(remarks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("get-committee-meetings/{groupId}")]
        public IHttpActionResult GetCommitteeMeetings(int groupId)
        {
            try
            {
                var meetings = db.GroupSchedules
                    .Where(gs => gs.groupID == groupId)
                    .Select(gs => new
                    {
                        gs.id,
                        MeetingId = gs.comiteeMeetingID,
                        MeetingTitle = gs.ComiteeMeeting.title,
                        Description = gs.ComiteeMeeting.meetingDescription,
                        Date = gs.ComiteeMeeting.startDate,
                        Venue = gs.ComiteeMeeting.venue,
                        Status = gs.Status ?? "Scheduled",
                        Time = gs.estimatedTime
                    })
                    .ToList()
                    .Select(m => new
                    {
                        m.id,
                        m.MeetingId,
                        m.MeetingTitle,
                        m.Description,
                        Date = m.Date.HasValue ? m.Date.Value.ToString("yyyy-MM-dd") : "",
                        m.Venue,
                        m.Status,
                        Time = m.Time.HasValue ? m.Time.Value.ToString() : "10:00"
                    })
                    .ToList();

                return Ok(meetings);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("get-all-remarks-history/{groupId}")]
        public IHttpActionResult GetAllRemarksHistory(int groupId)
        {
            try
            {
                // 1. Meeting Remarks
                var meetingRemarks = db.SupervisorRemarks
                    .Where(r => r.GroupID == groupId)
                    .ToList()
                    .Select(r => new
                    {
                        Type = "Meeting",
                        Remarks = r.Remarks,
                        Date = r.CreatedAt ?? DateTime.Now,
                        Context = db.SuperVisorMeetings.Where(m => m.id == r.MeetingID).Select(m => m.title).FirstOrDefault() ?? "General Meeting",
                        Target = r.StudentEnrollID == null 
                            ? "Entire Group" 
                            : db.Enrollments.Where(e => e.id == r.StudentEnrollID).Join(db.Students, e => e.studentID, s => s.regNum, (e, s) => s.name).FirstOrDefault() ?? "Individual Student"
                    })
                    .ToList();

                // 2. Task Evaluation Remarks
                var taskRemarks = (from t in db.Tasks
                                   join te in db.TaskEvaluations on t.id equals te.taskID
                                   where t.groupID == groupId && te.taskRemarks != null && te.taskRemarks != ""
                                   select new
                                   {
                                       Type = "Task",
                                       Remarks = te.taskRemarks,
                                       Date = te.submissionDate ?? DateTime.Now,
                                       Context = t.title,
                                       Target = t.studentID == null 
                                           ? "Entire Group" 
                                           : db.Students.Where(s => s.regNum == t.studentID).Select(s => s.name).FirstOrDefault() ?? "Individual Student"
                                   })
                                   .ToList()
                                   .Select(tr => new
                                   {
                                       Type = tr.Type,
                                       Remarks = tr.Remarks,
                                       Date = tr.Date,
                                       Context = tr.Context,
                                       Target = tr.Target
                                   })
                                   .ToList();

                var allRemarks = meetingRemarks
                    .Concat(taskRemarks)
                    .OrderByDescending(r => r.Date)
                    .ToList();

                return Ok(allRemarks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("get-remarks-history/{groupId}/{studentEnrollId?}")]
        public IHttpActionResult GetRemarksHistory(int groupId, int? studentEnrollId = null)
        {
            try
            {
                var query = db.SupervisorRemarks
                    .Where(r => r.GroupID == groupId);

                if (studentEnrollId.HasValue)
                {
                    query = query.Where(r => r.StudentEnrollID == studentEnrollId.Value);
                }
                else
                {
                    query = query.Where(r => r.StudentEnrollID == null);
                }

                var history = query
                    .OrderByDescending(r => r.CreatedAt)
                    .Select(r => new
                    {
                        r.Id,
                        r.Remarks,
                        r.CreatedAt,
                        r.MeetingID,
                        MeetingTitle = db.SuperVisorMeetings.Where(m => m.id == r.MeetingID).Select(m => m.title).FirstOrDefault()
                    })
                    .ToList();

                return Ok(history);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("save-supervisor-remarks")]
        public IHttpActionResult SaveSupervisorRemarks(SupervisorRemark model)
        {
            if (model == null)
                return BadRequest("Invalid data");

            var existing = db.SupervisorRemarks.FirstOrDefault(x =>
                x.GroupID == model.GroupID &&
                x.SupervisorID == model.SupervisorID &&
                (
                    (x.StudentEnrollID == null && model.StudentEnrollID == null) ||
                    (x.StudentEnrollID == model.StudentEnrollID)
                )
            );

            if (existing != null)
            {
                existing.Remarks = model.Remarks;
                existing.UpdatedAt = DateTime.Now;
            }
            else
            {
                model.CreatedAt = DateTime.Now;
                db.SupervisorRemarks.Add(model);
            }

            db.SaveChanges();

            return Ok(new { message = "Saved successfully" });
        }

        [HttpPost]
        [Route("schedule-meeting")]
        public async Task<IHttpActionResult> ScheduleMeeting(ScheduleMeetingRequest request)
        {
            if (request.EndDate < request.StartDate)
                return BadRequest("Invalid date range");

            if (string.IsNullOrWhiteSpace(request.Days))
                return BadRequest("Select at least one day");

            try
            {
                var selectedDays = request.Days
                    .Split(',')
                    .Select(d => d.Trim().ToLower()) // mon, wed
                    .ToList();

                var dayMap = new Dictionary<string, DayOfWeek>
                {
                    { "mon", DayOfWeek.Monday },
                    { "tue", DayOfWeek.Tuesday },
                    { "wed", DayOfWeek.Wednesday },
                    { "thu", DayOfWeek.Thursday },
                    { "fri", DayOfWeek.Friday },
                    { "sat", DayOfWeek.Saturday },
                    { "sun", DayOfWeek.Sunday }
                };

                var selectedDayEnums = selectedDays
                    .Where(d => dayMap.ContainsKey(d))
                    .Select(d => dayMap[d])
                    .ToList();

                var validDates = new List<DateTime>();
                DateTime tempDate = request.StartDate;

                while (tempDate <= request.EndDate)
                {
                    if (selectedDayEnums.Contains(tempDate.DayOfWeek))
                        validDates.Add(tempDate);

                    tempDate = tempDate.AddDays(1);
                }

                if (!validDates.Any())
                    return BadRequest("No valid meeting days found in the given date range.");

                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                var meetings = validDates.Select(date => new SuperVisorMeeting
                {
                    date = date,
                    time = request.Time,
                    day = date.DayOfWeek.ToString(),
                    venue = request.Location,
                    createdBy = request.SupervisorId,
                    groupID = request.GroupId,
                    memberId = request.MemberId,
                    isRecurring = true,
                    EndDate = request.EndDate,
                    title = request.Title,
                    description = request.Description,
                    pptRequired = request.PptRequired ? 1 : 0,
                    filePath = request.FilePath,
                    sessionId = currentSessionId
                }).ToList();

                db.SuperVisorMeetings.AddRange(meetings);
                await db.SaveChangesAsync();

                // Save recurring days linked to the FIRST created meeting (or all if preferred, but usually first is enough for reference)
                var firstMeeting = meetings.FirstOrDefault();
                if (firstMeeting != null)
                {
                    var recurringDays = selectedDays.Select(d => new RecurringMeetingDay
                    {
                        meetingID = firstMeeting.id,
                        meetingDay = Capitalize(d)
                    }).ToList();

                    db.RecurringMeetingDays.AddRange(recurringDays);
                    await db.SaveChangesAsync();
                }

                return Ok(new
                {
                    message = "Meeting scheduled successfully",
                    totalMeetings = meetings.Count
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("meetings/{meetingId}")]
        public IHttpActionResult GetMeetingDetails(int meetingId)
        {
            var meeting = db.SuperVisorMeetings
                .Where(m => m.id == meetingId)
                .Select(m => new
                {
                    m.id,
                    m.title,
                    m.date,
                    m.groupID
                })
                .FirstOrDefault();

            if (meeting == null)
                return NotFound();

            return Ok(meeting);
        }
        [HttpGet]
        [Route("groups/{groupId}")]
        public IHttpActionResult GetGroupWithMembers(int groupId)
        {

            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new
            {

                e.id,
                e.name


            }).FirstOrDefault();
            var group = db.ProjectGroups
                .Where(g => g.id == groupId)
                .Select(g => new
                {
                    g.id,
                    Members = g.GroupMembers.Select(m => new
                    { 
                        m.id,
                        m.Student.name,
                        m.Student.regNum,
                          EnrollmentID = db.Enrollments
                        .Where(e => e.studentID == m.studentID && e.sessionID == list.id)
                        .Select(e => e.id)
                        .FirstOrDefault(),
                    }).ToList()
                })
                .FirstOrDefault();

            if (group == null)
                return NotFound();

            return Ok(group);
        }

        [HttpGet]
        [Route("StudentTasks/{groupId}/{studentId}")]
        public IHttpActionResult GetStudentTasksByGroup(int groupId, string studentId)
        {
            try
            {
                // ✅ Check student belongs to group
                var isMember = db.GroupMembers
                    .Any(g => g.groupID == groupId && g.studentID == studentId);

                if (!isMember)
                    return BadRequest("Student does not belong to this group.");

                var tasks = db.Tasks
                    .Where(t =>
                        t.groupID == groupId &&
                        (
                            t.studentID == studentId ||   // Individual task
                            t.studentID == null           // Group task
                        )
                    )
                    .Select(t => new
                    {
                        t.id,
                        t.title,
                        t.taskDescription,
                        t.assignDate,
                        t.dueDate,
                        t.taskStatus,
                        t.isPptRequired,

                        // ✅ FIX: Always return numeric progress
                        progress = db.TaskEvaluations
                            .Where(e => e.taskID == t.id)
                            .Select(e => (int?)e.score)
                            .FirstOrDefault() ?? 0,

                        // ✅ Optional: also send status if needed
                        progressStatus = db.TaskEvaluations
                            .Where(e => e.taskID == t.id)
                            .Select(e => e.progressStatus)
                            .FirstOrDefault() ?? "Not Started",

                        AssignedType = t.studentID == null ? "Group" : "Individual"
                    })
                    .OrderBy(t => t.dueDate)
                    .ToList();

                return Ok(tasks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpGet]
        [Route("GroupTasks/{groupId}")]
        public IHttpActionResult GetAllGroupTasks(int groupId)
        {
            try
            {
                var tasks = db.Tasks
                    .Where(t => t.groupID == groupId)
                    .Select(t => new
                    {
                        t.id,
                        t.title,
                        t.taskDescription,
                        t.assignDate,
                        t.dueDate,
                        t.taskStatus,
                        t.isPptRequired,
                        t.studentID,
                        t.Student.name, 

                        // 🔹 Runtime assignment type
                        AssignedType = t.studentID == null ? "Group" : "Individual"
                    })
                    .OrderBy(t => t.dueDate)
                    .ToList();

                return Ok(tasks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        private string Capitalize(string day)
        {
            return char.ToUpper(day[0]) + day.Substring(1).ToLower();
        }


        // Add these to SuperVisorController.cs

        [HttpPost]
        [Route("assign-task")]
        public IHttpActionResult AssignTask(AssignTaskDto model)
        {
            try
            {
                if (model == null) return BadRequest("Invalid task data");

                var task = new ProgressMonitoringProject.Models.Task
                {
                    title = model.Title,
                    taskDescription = model.Description,
                    assignDate = DateTime.Now,
                    dueDate = model.DueDate,
                    assignedBy = model.SupervisorId,
                    groupID = model.GroupId,
                    studentID = model.AssigneeType == "individual" ? model.StudentId : null,
                    isPptRequired = model.IsPptRequired,
                    taskStatus = "Pending" // Initial status
                };

                db.Tasks.Add(task);
                db.SaveChanges();

                // 🔔 Notify Students
                try
                {
                    var notification = new ProgressMonitoringProject.Models.Notification
                    {
                        Title = "New Task Assigned",
                        Message = $"New task: {task.title}",
                        Type = "TaskAssignment",
                        ReferenceID = task.id,
                        CreatedAt = DateTime.Now,
                        SenderID = model.SupervisorId,
                        SenderRole = "Supervisor"
                    };
                    db.Notifications.Add(notification);
                    db.SaveChanges();

                    var recipients = model.AssigneeType == "individual" 
                        ? new List<string> { model.StudentId }
                        : db.GroupMembers.Where(gm => gm.groupID == model.GroupId).Select(gm => gm.studentID).ToList();

                    foreach (var sid in recipients)
                    {
                        db.NotificationRecipients.Add(new ProgressMonitoringProject.Models.NotificationRecipient
                        {
                            NotificationID = notification.NotificationID,
                            RecipientID = sid,
                            RecipientRole = "Student",
                            IsRead = 0
                        });
                    }
                    db.SaveChanges();
                }
                catch { }

                return Ok("Task Assigned Successfully ✅");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("edit-task")]
        public IHttpActionResult EditTask(EditTaskDto model)
        {
            try
            {
                var task = db.Tasks.FirstOrDefault(t => t.id == model.TaskId);
                if (task == null) return NotFound();

                task.title = model.Title;
                task.taskDescription = model.Description;
                task.dueDate = model.DueDate;

                db.SaveChanges();
                return Ok("Task Updated ✅");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        public class EditTaskDto
        {
            public int TaskId { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public DateTime DueDate { get; set; }
        }


        [HttpGet]
        [Route("get-supervisor-tasks/{supervisorId}/{fypType}")]
        public IHttpActionResult GetSupervisorTasks(string supervisorId, string fypType)
        {
            try
            {
                var currentSessionId = db.Sessions
                    .OrderByDescending(s => s.startDate)
                    .Select(s => s.id)
                    .FirstOrDefault();

                var tasks = db.Tasks
                    .Where(t => t.assignedBy == supervisorId)
                    .Join(db.ProjectGroups,
                        t => t.groupID,
                        pg => pg.id,
                        (t, pg) => new { t, pg })
                    .Where(x => x.pg.createdSession == currentSessionId)
                    // Filter by subject (FYP-1 / FYP-2) via Enrollment check
                    .Join(db.Enrollments.Where(e => e.subject == fypType),
                        x => x.pg.createdBy,
                        e => e.studentID,
                        (x, e) => new
                        {
                            x.t.id,
                            x.t.title,
                            x.t.taskDescription,
                            x.t.dueDate,
                            x.t.taskStatus,
                            x.t.studentID,
                            GroupName = "Group " + x.t.groupID,
                            StudentName = x.t.studentID != null ? db.Students.Where(s => s.regNum == x.t.studentID).Select(s => s.name).FirstOrDefault() : "Whole Group"
                        })
                    .Distinct()
                    .ToList();

                return Ok(tasks);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpPost]
        [Route("update-task-progress")]
        public IHttpActionResult UpdateTaskProgress(UpdateTaskProgressDto model)
        {
            try
            {
                int score = model.ProgressStatus switch
                {
                    "Initial" => 25,
                    "Partial" => 60,
                    "Complete" => 100,
                    _ => 0
                };

                // 🔍 find evaluation
                var evaluation = db.TaskEvaluations
                    .FirstOrDefault(e => e.taskID == model.TaskId);

                if (evaluation == null)
                {
                    evaluation = new TaskEvaluation
                    {
                        taskID = model.TaskId,
                        submissionDate = DateTime.Now
                    };
                    db.TaskEvaluations.Add(evaluation);
                }

                evaluation.progressStatus = model.ProgressStatus;
                evaluation.score = score;

                // 🔁 auto update task status
                var task = db.Tasks.FirstOrDefault(t => t.id == model.TaskId);
                if (task != null && score == 100)
                {
                    task.taskStatus = "Completed";
                }
                else if (task != null)
                {
                    task.taskStatus = "In Progress";
                }

                db.SaveChanges();

                return Ok(new
                {
                    model.ProgressStatus,
                    score
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("evaluate-task")]
        public IHttpActionResult EvaluateTask(EvaluateTaskDto model)
        {
            try
            {
                if (model == null)
                    return BadRequest("Invalid evaluation data");

                // 🔹 Calculate score automatically if not provided
                int score = model.Score ?? model.ProgressStatus switch
                {
                    "Initial" => 25,
                    "Partial" => 60,
                    "Complete" => 100,
                    _ => 0
                };

                // 🔍 Check if evaluation already exists
                var evaluation = db.TaskEvaluations
                    .FirstOrDefault(e => e.taskID == model.TaskId);

                if (evaluation ==
                    null)
                {
                    evaluation = new TaskEvaluation
                    {
                        taskID = model.TaskId,
                        submissionDate = DateTime.Now
                    };
                    db.TaskEvaluations.Add(evaluation);
                }

                // ✏️ Update evaluation
                evaluation.progressStatus = model.ProgressStatus;
                evaluation.score = score;
                evaluation.taskRemarks = model.Remarks;

                // 🔁 Auto-update task status
                var task = db.Tasks.FirstOrDefault(t => t.id == model.TaskId);
                if (task != null)
                {
                    task.taskStatus = (model.ProgressStatus == "Complete" || score == 100) ? "Completed" : "In Progress";
                }

                db.SaveChanges();

                return Ok(new
                {
                    message = "Task evaluated successfully",
                    model.TaskId,
                    model.ProgressStatus,
                    score,
                    model.Remarks
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        public class UpdateTaskProgressDto
        {
            public int TaskId { get; set; }
            public string ProgressStatus { get; set; } // Initial | Partial | Complete
        }
        public class EvaluateTaskDto
        {
            public int TaskId { get; set; }

            // Initial | Partial | Complete
            public string ProgressStatus { get; set; }

            // Optional (auto-calculated if null)
            public int? Score { get; set; }

            // Supervisor feedback
            public string Remarks { get; set; }
        }
        public class AssignTaskDto
        {
            public string Title { get; set; }
            public string Description { get; set; }
            public DateTime DueDate { get; set; }
            public string SupervisorId { get; set; }
            public int GroupId { get; set; }
            public string AssigneeType { get; set; } // "group" or "individual"
            public string StudentId { get; set; }
            public bool IsPptRequired { get; set; }
        }


        public class AttendanceDto
        {
            public int MeetingId { get; set; }
            public List<StudentAttendanceDto> Attendance { get; set; }
        }

        public class StudentAttendanceDto
        {
            public int memberId { get; set; }
            public bool IsPresent { get; set; }
        }
        public class SupervisorMeetingDto
        {
            public int Id { get; set; }
            public DateTime? Date { get; set; }
            public TimeSpan? Time { get; set; }
            public string Day { get; set; }
            public string Venue { get; set; }
            public string CreatedBy { get; set; }
            public int? GroupId { get; set; }
            public string memberId { get; set; }

            public bool IsRecurring { get; set; }
            public DateTime? EndDate { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public int? PptRequired { get; set; }

            public List<string> RecurringDays { get; set; }
        }
        public class ScheduleMeetingRequest
        {
            public string SupervisorId { get; set; }
            public int? GroupId { get; set; }
            public string? MemberId { get; set; }

            public string Title { get; set; }
            public string Description { get; set; }

            public DateTime StartDate { get; set; }
            public DateTime EndDate { get; set; }

            public TimeSpan Time { get; set; }
            public string Days { get; set; }

            public string Location { get; set; }

            public bool PptRequired { get; set; }
            public string FilePath { get; set; } // store path only
        }

        [HttpPost]
        [Route("upload-task-ppt")]
        public IHttpActionResult UploadTaskPpt()
        {
            if (!Request.Content.IsMimeMultipartContent())
                return BadRequest("Invalid format. Use multipart/form-data.");

            try
            {
                var httpRequest = System.Web.HttpContext.Current.Request;
                int taskId = Convert.ToInt32(httpRequest["taskId"]);
                
                var task = db.Tasks.Find(taskId);
                if (task == null) return NotFound();

                var postedFile = httpRequest.Files["file"];
                if (postedFile == null)
                    return BadRequest("File is required.");

                string folderPath = System.Web.HttpContext.Current.Server.MapPath("~/Uploads/Tasks/");
                if (!System.IO.Directory.Exists(folderPath))
                    System.IO.Directory.CreateDirectory(folderPath);

                string fileName = $"{taskId}_{DateTime.Now.Ticks}{System.IO.Path.GetExtension(postedFile.FileName)}";
                string filePath = System.IO.Path.Combine(folderPath, fileName);
                postedFile.SaveAs(filePath);

                string virtualPath = $"/Uploads/Tasks/{fileName}";

                var evaluation = db.TaskEvaluations.FirstOrDefault(e => e.taskID == taskId);
                if (evaluation == null)
                {
                    evaluation = new TaskEvaluation
                    {
                        taskID = taskId,
                        submissionFilePath = virtualPath,
                        submissionDate = DateTime.Now,
                        progressStatus = "Submitted",
                        score = 0
                    };
                    db.TaskEvaluations.Add(evaluation);
                }
                else
                {
                    evaluation.submissionFilePath = virtualPath;
                    evaluation.submissionDate = DateTime.Now;
                    if (evaluation.progressStatus == "Not Started" || string.IsNullOrEmpty(evaluation.progressStatus))
                    {
                        evaluation.progressStatus = "Submitted";
                    }
                }

                // If task status was "Pending", upgrade to "Submitted" or "In Progress"
                if (task.taskStatus == "Pending")
                {
                    task.taskStatus = "In Progress";
                }

                db.SaveChanges();

                return Ok(new { message = "Task PPT uploaded successfully", filePath = virtualPath });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("suggest-project")]
        public async Task<IHttpActionResult> SuggestProject([System.Web.Http.FromBody] ProjectSuggestionDto model)
        {
            if (model == null || string.IsNullOrWhiteSpace(model.Title))
            {
                return BadRequest("Invalid project data");
            }

            try
            {
                // 1. Get the current active session ID
                var currentSession = await db.Sessions
                    .OrderByDescending(s => s.id)
                    .FirstOrDefaultAsync();

                if (currentSession == null)
                {
                    return BadRequest("No active session found.");
                }

                // 2. Create the Project record
                var project = new Project
                {
                    title = model.Title,
                    suggestedBy = model.SupervisorId,
                    projectStatus = model.ProjectStatus ?? true,
                    objectives = model.Objectives
                };

                db.Projects.Add(project);
                await db.SaveChangesAsync();

                // 3. Link the Project to the current session in OfferedProjects
                var offeredProject = new OfferedProject
                {
                    sessionID = currentSession.id,
                    projectID = project.id
                };

                db.OfferedProjects.Add(offeredProject);
                await db.SaveChangesAsync();

                return Ok(new { 
                    message = "Project suggested successfully", 
                    projectId = project.id, 
                    offeredProjectId = offeredProject.id 
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }

    public class ProjectSuggestionDto
    {
        public string Title { get; set; }
        public string Objectives { get; set; }
        public string SupervisorId { get; set; }
        public bool? ProjectStatus { get; set; }
    }
}