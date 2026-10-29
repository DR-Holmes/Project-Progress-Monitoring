using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ProgressMonitoringProject.Models
{
    public class SupervisorMeetingRequest
    {
        public int GroupId { get; set; }
        public string Venue { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TimeSpan MeetingTime { get; set; }
        public List<string> SelectedDays { get; set; } // Mon, Tue, Wed...
        public bool IsFileRequired { get; set; }
    }

}