//using ProgressMonitoringProject.Models;
//using System.Linq;
//using System.Web.Http;

//public class SuperVisorAttendanceController : ApiController
//{
//    FypProjectProgDBEntities db = new FypProjectProgDBEntities();

//    [HttpGet]
//    public IHttpActionResult GetAllSupervisorAttendances()
//    {
//        var data = db.SuperVisorAttendances
//            .Select(sa => new
//            {
//                sa.id,
//                sa.attendanceDate,
//                sa.isAttend,

//                meeting = new
//                {
//                    sa.meetingID,
//                    sa.SuperVisorMeeting.date,
//                    sa.SuperVisorMeeting.time,
//                    sa.SuperVisorMeeting.day,
//                    sa.SuperVisorMeeting.venue,
//                    sa.SuperVisorMeeting.isRecurring,

//                    createdBy = new
//                    {
//                        sa.SuperVisorMeeting.createdBy,
//                        name = sa.SuperVisorMeeting.User.name,
//                        email = sa.SuperVisorMeeting.User.email
//                    },

//                    group = new
//                    {
//                        sa.SuperVisorMeeting.groupID,
//                        groupName = sa.SuperVisorMeeting.ProjectGroup.id,
//                        supervisorId = sa.SuperVisorMeeting.ProjectGroup.supervisorID
//                    }
//                }
//            })
//            .ToList();

//        return Ok(data);
//    }

//    [HttpGet]
//    public IHttpActionResult GetSupervisorAttendance(int id)
//    {
//        var sa = db.SuperVisorAttendances
//            .Where(x => x.id == id)
//            .Select(s => new
//            {
//                s.id,
//                s.attendanceDate,
//                s.isAttend,

//                meeting = new
//                {
//                    s.meetingID,
//                    s.SuperVisorMeeting.date,
//                    s.SuperVisorMeeting.time,
//                    s.SuperVisorMeeting.day,
//                    s.SuperVisorMeeting.venue,
//                    s.SuperVisorMeeting.isRecurring,

//                    createdBy = new
//                    {
//                        s.SuperVisorMeeting.createdBy,
//                        name = s.SuperVisorMeeting.User.name,
//                        email = s.SuperVisorMeeting.User.email
//                    },

//                    group = new
//                    {
//                        s.SuperVisorMeeting.groupID,
//                        groupName = s.SuperVisorMeeting.ProjectGroup.id,
//                        supervisorId = s.SuperVisorMeeting.ProjectGroup.supervisorID
//                    }
//                }
//            })
//            .FirstOrDefault();

//        if (sa == null) return NotFound();

//        return Ok(sa);
//    }


//    [HttpPost]
//    public IHttpActionResult Add(SuperVisorAttendance model)
//    {
//        db.SuperVisorAttendances.Add(model);
//        db.SaveChanges();
//        return Ok("Attendance Added");
//    }

//    [HttpPut]
//    public IHttpActionResult Update(int id, SuperVisorAttendance model)
//    {
//        var data = db.SuperVisorAttendances.Find(id);
//        if (data == null) return NotFound();

//        db.Entry(data).CurrentValues.SetValues(model);
//        db.SaveChanges();
//        return Ok("Attendance Updated");
//    }

//    [HttpDelete]
//    public IHttpActionResult Delete(int id)
//    {
//        var data = db.SuperVisorAttendances.Find(id);
//        if (data == null) return NotFound();

//        db.SuperVisorAttendances.Remove(data);
//        db.SaveChanges();
//        return Ok("Deleted Successfully");
//    }
//}
