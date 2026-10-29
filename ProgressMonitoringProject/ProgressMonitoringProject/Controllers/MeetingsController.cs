//using ProgressMonitoringProject.Models;
//using System.Collections.Generic;
//using System;
//using System.Linq;
//using System.Threading.Tasks;
//using System.Web.Http;
//using System.Data.Entity;

//namespace ProgressMonitoringProject.Controllers
//{
   
//    [RoutePrefix("api/meetings")]
//    public class MeetingsController : ApiController
//    {
//        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();


       
//        [HttpGet, Route("supervisor")]
//        public IHttpActionResult GetAllSupervisorMeetings()
//        {
//            var meetings = db.SuperVisorMeetings

//                .Select(m => new
//                {
//                    m.id,
//                    m.date,
//                    m.time,
//                    m.day,
//                    m.venue,
//                    m.isRecurring,

//                    createdBy = new
//                    {
//                        m.createdBy,
//                        name = m.User.name,
//                        email = m.User.email
//                    },

//                    group = new
//                    {
//                        m.groupID,
//                        groupName = m.ProjectGroup.id,
//                        supervisorId = m.ProjectGroup.supervisorID
//                    }
//                }).ToList();

//            return Ok(meetings);
//        }


//        [HttpGet, Route("supervisor/{id}")]
//        public IHttpActionResult GetSupervisorMeeting(int id)
//        {
//            var meeting = db.SuperVisorMeetings
//                .Where(m => m.id == id)
//                .Select(m => new
//                {
//                    m.id,
//                    m.date,
//                    m.time,
//                    m.day,
//                    m.venue,
//                    m.isRecurring,

//                    createdBy = new
//                    {
//                        m.createdBy,
//                        name = m.User.name,
//                        email = m.User.email
//                    },

//                    group = new
//                    {
//                        m.groupID,
//                        groupName = m.ProjectGroup.id,
//                        supervisorId = m.ProjectGroup.supervisorID
//                    }
//                })
//                .FirstOrDefault();

//            if (meeting == null) return NotFound();

//            return Ok(meeting);
//        }


       
//        [HttpPost, Route("supervisor/add")]
//        public IHttpActionResult AddSupervisorMeeting(SuperVisorMeeting model)
//        {
//            db.SuperVisorMeetings.Add(model);
//            db.SaveChanges();
//            return Ok("Supervisor Meeting Added");
//        }


      
//        [HttpPut, Route("supervisor/update/{id}")]
//        public IHttpActionResult UpdateSupervisorMeeting(int id, SuperVisorMeeting model)
//        {
//            var data = db.SuperVisorMeetings.Find(id);
//            if (data == null) return NotFound();

//            db.Entry(data).CurrentValues.SetValues(model);
//            db.SaveChanges();
//            return Ok("Supervisor Meeting Updated");
//        }


        
//        [HttpDelete, Route("supervisor/delete/{id}")]
//        public IHttpActionResult DeleteSupervisorMeeting(int id)
//        {
//            var data = db.SuperVisorMeetings.Find(id);
//            if (data == null) return NotFound();

//            db.SuperVisorMeetings.Remove(data);
//            db.SaveChanges();
//            return Ok("Supervisor Meeting Deleted");
//        }


     
//        [HttpGet, Route("committee")]
//        public IHttpActionResult GetAllCommitteeMeetings()
//        {
//            var meetings = db.ComiteeMeetings
//                .Select(m => new
//                {
//                    m.id,
//                    m.meetingDescription,
//                    m.startDate,
//                    m.endDate,
//                    m.startTime,
//                    m.endTime,
//                    m.venue,
//                    m.selectedDays,
//                    m.isGraded,
//                    m.isFileRequired,
//                    session = new
//                    {
//                        m.sessionID,
//                        sessionName = m.Session.name,
//                        startDate = m.Session.startDate
//                    }
//                })
//                .ToList();

//            return Ok(meetings);
//        }


     
//        [HttpGet, Route("committee/{id}")]
//        public IHttpActionResult GetCommitteeMeeting(int id)
//        {
//            var meeting = db.ComiteeMeetings
//                .Where(m => m.id == id)
//                .Select(m => new
//                {
//                    m.id,
//                    m.meetingDescription,
//                    m.startDate,
//                    m.endDate,
//                    m.startTime,
//                    m.endTime,
//                    m.venue,
//                    m.selectedDays,
//                    m.isGraded,
//                    m.isFileRequired,
//                    session = new
//                    {
//                        m.sessionID,
//                        sessionName = m.Session.name,
//                        startDate = m.Session.startDate
//                    }
//                })
//                .FirstOrDefault();

//            if (meeting == null) return NotFound();

//            return Ok(meeting);
//        }


   
//        [HttpPost, Route("add")]
//        public IHttpActionResult AddCommitteeMeeting(ComiteeMeeting model)
//        {
//            db.ComiteeMeetings.Add(model);
//            db.SaveChanges();
//            return Ok("Committee Meeting Added");
//        }


       
//        [HttpPut, Route("update/{id}")]
//        public IHttpActionResult UpdateCommitteeMeeting(int id, ComiteeMeeting model)
//        {
//            var data = db.ComiteeMeetings.Find(id);
//            if (data == null) return NotFound();

//            db.Entry(data).CurrentValues.SetValues(model);
//            db.SaveChanges();
//            return Ok("Committee Meeting Updated");
//        }


       
//        [HttpDelete, Route("delete/{id}")]
//        public IHttpActionResult DeleteCommitteeMeeting(int id)
//        {
//            var data = db.ComiteeMeetings.Find(id);
//            if (data == null) return NotFound();

//            db.ComiteeMeetings.Remove(data);
//            db.SaveChanges();
//            return Ok("Committee Meeting Deleted");
//        }

     
//        [HttpGet]
//        [Route("GetGroupMeetingDetails/{groupScheduleId}")]
//        public IHttpActionResult GetMeetingScreenDetails(int groupScheduleId)
//        {

//            var meetingHeader = db.GroupSchedules
//                .Join(db.ComiteeMeetings,
//                      gs => gs.comiteeMeetingID,
//                      cm => cm.id,
//                      (gs, cm) => new { gs, cm })
//                .Where(x => x.gs.id == groupScheduleId)
//                .Select(x => new
//                {
//                    MeetingTitle = x.cm.meetingDescription,
//                    MeetingDate = x.cm.startDate,
//                    GroupId = x.gs.groupID
//                })
//                .FirstOrDefault();

//            if (meetingHeader == null) return NotFound();


//            var attendanceList = db.GroupMembers
//                .Where(gm => gm.groupID == meetingHeader.GroupId) 
//                .Join(db.Students,
//                      gm => gm.studentID,
//                      s => s.regNum,
//                      (gm, s) => new { GroupMember = gm, Student = s })

//                .GroupJoin(db.MeetingAttendances,
//                           combined => combined.GroupMember.id,
//                           ma => ma.studentID,
//                           (combined, maCollection) => new { combined, maCollection })
//                .SelectMany(
//                    x => x.maCollection.Where(ma => ma.scheduleID == groupScheduleId).DefaultIfEmpty(),
//                    (x, ma) => new StudentAttendanceDto
//                    {
//                        GroupMemberId = x.combined.GroupMember.id,
//                        StudentName = x.combined.Student.name,
//                        RegNum = x.combined.Student.regNum,
//                        IsPresent = ma != null ? (bool)ma.attendance : false
//                    }
//                ).ToList();

//            return Ok(new MeetingScreenDto
//            {
//                MeetingTitle = meetingHeader.MeetingTitle,
//                MeetingDate = meetingHeader.MeetingDate,
//                GroupId = (int)meetingHeader.GroupId,
//                Students = attendanceList
//            });
//        }

        
//        [HttpPost]
//        [Route("meetingAttendance/{groupScheduleId}")]
//        public IHttpActionResult MarkAttendance(int groupScheduleId, List<StudentAttendanceDto> attendanceData)
//        {
//            foreach (var item in attendanceData)
//            {

//                var existingRecord = db.MeetingAttendances
//                    .FirstOrDefault(ma => ma.scheduleID == groupScheduleId &&
//                                         ma.studentID == item.GroupMemberId);

//                if (existingRecord != null)
//                {

//                    existingRecord.attendance = item.IsPresent;
//                }
//                else
//                {

//                    var newAttendance = new MeetingAttendance
//                    {
//                        scheduleID = groupScheduleId,
//                        studentID = item.GroupMemberId,
//                        attendance = item.IsPresent,
//                        remarks = null
//                    };
//                    db.MeetingAttendances.Add(newAttendance);
//                }
//            }

//            db.SaveChanges();
//            return Ok("Attendence marked");
//        }

       
//        [HttpGet]
//        [Route("queue/today")]
//        public IHttpActionResult GetTodayMeetingQueue(string fypStage, string supervisorFilter = null)
//        {

//            var today = DateTime.Today;

//            var queue = db.MeetingQueues
//                .Join(db.GroupSchedules,
//                      mq => mq.scheduleID,
//                      gs => gs.id,
//                      (mq, gs) => new { mq, gs })
//                .Where(x => x.mq.meetingDate.HasValue && DbFunctions.TruncateTime(x.mq.meetingDate.Value) == today)
//                .Join(db.ProjectGroups,
//                      x => x.gs.groupID,
//                      pg => pg.id,
//                      (x, pg) => new { x.mq, x.gs, pg })
//                .Join(db.Users,
//                      x => x.pg.supervisorID,
//                      u => u.id,
//                      (x, u) => new { x.mq, x.gs, x.pg, SupervisorName = u.name })

//                .Where(x => supervisorFilter == null || x.SupervisorName.Contains(supervisorFilter))
//                .Select(x => new QueueItemDto
//                {
//                    MeetingQueueId = x.mq.id,
//                    GroupScheduleId = x.gs.id,
//                    GroupId = x.pg.id,
//                    GroupName = x.pg.id, 
//                    SupervisorName = x.SupervisorName,
//                    QueueStatus = x.mq.status,
//                    EstimatedTime = x.mq.meetingDate,

//                    Members = db.GroupMembers
//                                 .Where(gm => gm.groupID == x.pg.id)
//                                 .Join(db.Students,
//                                       gm => gm.studentID,
//                                       s => s.regNum,
//                                       (gm, s) => new MemberDetailDto
//                                       {
//                                           RegNum = s.regNum,
//                                           Name = s.name,
//                                           Gender = s.gender,
//                                           IsPresent = db.MeetingAttendances
//                                                           .Any(ma => ma.scheduleID == x.gs.id && ma.studentID == gm.id && ma.attendance == true)
//                                       })
//                                 .ToList()
//                })

//                .OrderByDescending(q => q.QueueStatus == "in meeting")
//                .ThenBy(q => q.EstimatedTime)
//                .ToList();

//            return Ok(queue);
//        }

        
//        [HttpPut]
//        [Route("queue/attendance/{groupScheduleId}/member/{groupMemberId}")]
//        public IHttpActionResult MarkQueueAttendance(int groupScheduleId, int groupMemberId, bool isPresent)
//        {

//            var existingRecord = db.MeetingAttendances
//                .FirstOrDefault(a => a.scheduleID == groupScheduleId && a.studentID == groupMemberId);

//            if (existingRecord != null)
//            {

//                existingRecord.attendance = isPresent;
//            }
//            else
//            {

//                db.MeetingAttendances.Add(new MeetingAttendance
//                {
//                    scheduleID = groupScheduleId,
//                    studentID = groupMemberId,
//                    attendance = isPresent,
//                    remarks = null
//                });
//            }

//            db.SaveChanges();
//            return Ok(true);
//        }

//        protected override void Dispose(bool disposing)
//        {
//            if (disposing) db.Dispose();
//            base.Dispose(disposing);
//        }
//    }

//    public class MeetingScreenDto
//    {
//        public string MeetingTitle { get; set; }
//        public DateTime? MeetingDate { get; set; }
//        public int GroupId { get; set; }
//        public List<StudentAttendanceDto> Students { get; set; }
//    }

//    public class StudentAttendanceDto
//    {
//        public int GroupMemberId { get; set; }
//        public string StudentName { get; set; }
//        public string RegNum { get; set; }
//        public bool IsPresent { get; set; }
//    }

//    public class AssignedTaskDto
//    {
//        public int TaskId { get; set; }
//        public string TaskTitle { get; set; }
//        public string AssignedTo { get; set; }
//        public bool IsGroupTask { get; set; }
//    }

//    public class CreateTaskDto
//    {
//        public string Title { get; set; }
//        public string Description { get; set; }
//        public int GroupId { get; set; }
//        public string SupervisorId { get; set; }
//        public DateTime DueDate { get; set; }
//        public bool IsWholeGroup { get; set; }
//        public string TargetStudentRegNum { get; set; }
//    }

//    public class QueueItemDto
//    {
//        public int MeetingQueueId { get; set; }
//        public int GroupScheduleId { get; set; }
//        public int GroupId { get; set; }
//        public int GroupName { get; set; } 
//        public string SupervisorName { get; set; }
//        public string QueueStatus { get; set; }
//        public DateTime? EstimatedTime { get; set; }
//        public List<MemberDetailDto> Members { get; set; }
//    }

//    public class MemberDetailDto
//    {
//        public string RegNum { get; set; }
//        public string Name { get; set; }
//        public string Gender { get; set; }
//        public bool IsPresent { get; set; }
//    }
//}