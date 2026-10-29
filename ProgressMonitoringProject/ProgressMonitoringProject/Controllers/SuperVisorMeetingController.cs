using ProgressMonitoringProject.Models;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Mvc;
using HttpPostAttribute = System.Web.Http.HttpPostAttribute;
using RouteAttribute = System.Web.Http.RouteAttribute;


[System.Web.Http.RoutePrefix("api/supervisorMeeting")]

public class SuperVisorMeetingController : ApiController
{
    private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

    [HttpPost]
    [Route("scheduleMeeting")]
    public async Task<IHttpActionResult> ScheduleSupervisorMeeting([FromBody] SupervisorMeetingRequest model)
    {

  
    string supervisorId = User.Identity.Name;

        var meeting = new SuperVisorMeeting
        {
            date = model.StartDate,
            time = model.MeetingTime,
            venue = model.Venue,
            createdBy = supervisorId,
            groupID = model.GroupId,
            isRecurring = true
        };

        db.SuperVisorMeetings.Add(meeting);
        await db.SaveChangesAsync();

     
        foreach (var day in model.SelectedDays)
        {
            var recurringDay = new RecurringMeetingDay
            {
                meetingID = meeting.id,
                meetingDay = day
            };

            db.RecurringMeetingDays.Add(recurringDay);
        }

        await db.SaveChangesAsync();

        await db.SaveChangesAsync();

        // Notify Group Members
        NotifyGroup(meeting.id, model.GroupId, "Supervisor Meeting Scheduled", $"Your supervisor has scheduled a meeting for {meeting.date:dd MMM yyyy} at {meeting.venue}", supervisorId);

        return Ok(new
        {
            Message = "Supervisor meeting scheduled successfully",
            MeetingId = meeting.id
        });
    }

    private void NotifyGroup(int meetingId, int groupId, string title, string message, string senderId)
    {
        try
        {
            var notification = new Notification
            {
                Title = title,
                Message = message,
                Type = "SupervisorMeeting",
                ReferenceID = meetingId,
                CreatedAt = System.DateTime.Now,
                SenderID = senderId,
                SenderRole = "Supervisor"
            };
            db.Notifications.Add(notification);
            db.SaveChanges();

            var members = db.GroupMembers.Where(gm => gm.groupID == groupId).Select(gm => gm.studentID).ToList();
            foreach (var studentId in members)
            {
                db.NotificationRecipients.Add(new NotificationRecipient
                {
                    NotificationID = notification.NotificationID,
                    RecipientID = studentId,
                    RecipientRole = "Student",
                    IsRead = 0
                });
            }
            db.SaveChanges();
        }
        catch { }
    }
}
