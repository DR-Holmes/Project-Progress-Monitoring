using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ProgressMonitoringProject.Models
{
    public class GroupRequestModel
    {
        public string fromRegNum { get; set; }
        public int sessionID { get; set; }
        public List<string> members { get; set; }
    }

}