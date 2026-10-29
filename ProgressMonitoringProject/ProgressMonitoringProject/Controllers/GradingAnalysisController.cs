using ProgressMonitoringProject.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/grading-analysis")]
    public class GradingAnalysisController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        // 1. Session-Wise Grade Distribution
        [HttpGet]
        [Route("session-wise")]
        public IHttpActionResult GetSessionWiseDistribution(string fyp = "FYP-1")
        {
            var sessions = db.Sessions.ToList();
            var enrollments = db.Enrollments.Where(e => e.subject == fyp).ToList();

            var result = sessions.Select(s => new {
                SessionId = s.id,
                SessionName = s.name,
                TotalStudents = enrollments.Count(e => e.sessionID == s.id),
                Grades = new {
                    APlus = enrollments.Count(e => e.sessionID == s.id && e.grade == "A+"),
                    A = enrollments.Count(e => e.sessionID == s.id && e.grade == "A"),
                    AMinus = enrollments.Count(e => e.sessionID == s.id && e.grade == "A-"),
                    BPlus = enrollments.Count(e => e.sessionID == s.id && e.grade == "B+"),
                    B = enrollments.Count(e => e.sessionID == s.id && e.grade == "B"),
                    BMinus = enrollments.Count(e => e.sessionID == s.id && e.grade == "B-"),
                    CPlus = enrollments.Count(e => e.sessionID == s.id && e.grade == "C+"),
                    C = enrollments.Count(e => e.sessionID == s.id && e.grade == "C"),
                    CMinus = enrollments.Count(e => e.sessionID == s.id && e.grade == "C-"),
                    DPlus = enrollments.Count(e => e.sessionID == s.id && e.grade == "D+"),
                    D = enrollments.Count(e => e.sessionID == s.id && e.grade == "D"),
                    F = enrollments.Count(e => e.sessionID == s.id && e.grade == "F"),
                    Ungraded = enrollments.Count(e => e.sessionID == s.id && (e.grade == null || e.grade == "" || e.grade == "Select Grade"))
                }
            }).ToList();

            return Ok(result);
        }

        // 2. Supervisor-Wise Grade Distribution
        [HttpGet]
        [Route("supervisor-wise")]
        public IHttpActionResult GetSupervisorWiseDistribution(string fyp = "FYP-1")
        {
            var supervisors = db.Users.Where(u => u.role == "Supervisor" || u.role == "Faculty").ToList();
            var groups = db.ProjectGroups.ToList();
            var groupMembers = db.GroupMembers.ToList();
            var enrollments = db.Enrollments.Where(e => e.subject == fyp).ToList();
            var sessions = db.Sessions.ToList();

            var result = supervisors.Select(sup => {
                var supGroupIds = groups.Where(g => g.supervisorID == sup.id).Select(g => g.id).ToList();
                var memberRegNums = groupMembers.Where(gm => supGroupIds.Contains(gm.groupID ?? 0)).Select(gm => gm.studentID).ToList();
                var supEnrollments = enrollments.Where(e => memberRegNums.Contains(e.studentID)).ToList();

                var sessionBreakdowns = sessions.Select(s => {
                    var sessEnrollments = supEnrollments.Where(e => e.sessionID == s.id).ToList();
                    return new {
                        SessionId = s.id,
                        SessionName = s.name,
                        TotalSupervised = sessEnrollments.Count,
                        Grades = new {
                            APlus = sessEnrollments.Count(e => e.grade == "A+"),
                            A = sessEnrollments.Count(e => e.grade == "A"),
                            AMinus = sessEnrollments.Count(e => e.grade == "A-"),
                            BPlus = sessEnrollments.Count(e => e.grade == "B+"),
                            B = sessEnrollments.Count(e => e.grade == "B"),
                            BMinus = sessEnrollments.Count(e => e.grade == "B-"),
                            CPlus = sessEnrollments.Count(e => e.grade == "C+"),
                            C = sessEnrollments.Count(e => e.grade == "C"),
                            CMinus = sessEnrollments.Count(e => e.grade == "C-"),
                            DPlus = sessEnrollments.Count(e => e.grade == "D+"),
                            D = sessEnrollments.Count(e => e.grade == "D"),
                            F = sessEnrollments.Count(e => e.grade == "F"),
                            Ungraded = sessEnrollments.Count(e => e.grade == null || e.grade == "" || e.grade == "Select Grade")
                        }
                    };
                }).ToList();

                return new {
                    SupervisorId = sup.id,
                    SupervisorName = sup.name,
                    TotalSupervised = supEnrollments.Count,
                    SessionBreakdowns = sessionBreakdowns,
                    Grades = new {
                        APlus = supEnrollments.Count(e => e.grade == "A+"),
                        A = supEnrollments.Count(e => e.grade == "A"),
                        AMinus = supEnrollments.Count(e => e.grade == "A-"),
                        BPlus = supEnrollments.Count(e => e.grade == "B+"),
                        B = supEnrollments.Count(e => e.grade == "B"),
                        BMinus = supEnrollments.Count(e => e.grade == "B-"),
                        CPlus = supEnrollments.Count(e => e.grade == "C+"),
                        C = supEnrollments.Count(e => e.grade == "C"),
                        CMinus = supEnrollments.Count(e => e.grade == "C-"),
                        DPlus = supEnrollments.Count(e => e.grade == "D+"),
                        D = supEnrollments.Count(e => e.grade == "D"),
                        F = supEnrollments.Count(e => e.grade == "F"),
                        Ungraded = supEnrollments.Count(e => e.grade == null || e.grade == "" || e.grade == "Select Grade")
                    }
                };
            }).ToList();

            return Ok(result);
        }

        // 3. Group-Wise Detailed Analysis
        [HttpGet]
        [Route("group-wise")]
        public IHttpActionResult GetGroupWiseDetails()
        {
            var groups = db.ProjectGroups.ToList();
            var groupMembers = db.GroupMembers.ToList();
            var enrollments = db.Enrollments.ToList();
            var offeredProjects = db.OfferedProjects.ToList();
            var projects = db.Projects.ToList();
            var users = db.Users.ToList();
            var sessions = db.Sessions.ToList();

            var result = groups.Select(g => {
                var supervisor = users.FirstOrDefault(u => u.id == g.supervisorID);
                var session = sessions.FirstOrDefault(s => s.id == g.createdSession);

                string projectTitle = "No Project Assigned";
                var offered = offeredProjects.FirstOrDefault(op => op.id == g.projectID);
                if (offered != null)
                {
                    var proj = projects.FirstOrDefault(p => p.id == offered.projectID);
                    if (proj != null) projectTitle = proj.title;
                }

                var members = groupMembers.Where(gm => gm.groupID == g.id).Select(gm => {
                    var studentUser = users.FirstOrDefault(u => u.id == gm.studentID);
                    var studentEnrollmentFyp1 = enrollments.FirstOrDefault(e => e.studentID == gm.studentID && e.sessionID == g.createdSession && e.subject == "FYP-1");
                    var studentEnrollmentFyp2 = enrollments.FirstOrDefault(e => e.studentID == gm.studentID && e.sessionID == g.createdSession && e.subject == "FYP-2");

                    return new {
                        RegNum = gm.studentID,
                        StudentName = studentUser != null ? studentUser.name : gm.studentID,
                        Fyp1Grade = studentEnrollmentFyp1 != null ? studentEnrollmentFyp1.grade : null,
                        Fyp2Grade = studentEnrollmentFyp2 != null ? studentEnrollmentFyp2.grade : null
                    };
                }).ToList();

                return new {
                    GroupId = g.id,
                    ProjectTitle = projectTitle,
                    SupervisorName = supervisor != null ? supervisor.name : "Unassigned",
                    SessionName = session != null ? session.name : "Unknown",
                    Members = members
                };
            }).ToList();

            return Ok(result);
        }
    }
}