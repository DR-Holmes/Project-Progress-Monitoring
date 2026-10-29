using ProgressMonitoringProject.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/fyp1-scores")]
    public class FYP1ScoreController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpPost]
        [Route("assign-parameters-to-meeting")]
        public IHttpActionResult AssignParametersToMeeting(AssignParametersDto dto)
        {
            foreach (var paramId in dto.ParameterIds)
            {
                db.MeetingParameterMappings.Add(new MeetingParameterMapping
                {
                    meetingID = dto.MeetingId,
                    parameterID = paramId
                });
            }

            db.SaveChanges();
            return Ok("Parameters assigned to meeting");
        }
        [HttpGet]
        [Route("get-remarks/{studentEnrollID}/{evaluatorID}/{sessionID}")]
        public IHttpActionResult GetAllRemarksByEvaluator(
    int studentEnrollID,
    string evaluatorID,
    int sessionID)
        {
            try
            {
                var remarks = db.FypStudentEvaluationRemarks
                    .Where(r =>
                        r.studentEnrollID == studentEnrollID &&
                        r.evaluatorID == evaluatorID &&
                        r.sessionID == sessionID
                    )
                    .OrderByDescending(r => r.updatedAt ?? r.createdAt)
                    .Select(r => new
                    {
                        r.id,
                        r.meetingID,
                        r.remarks,
                        r.createdAt,
                        r.updatedAt
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

            var existing = db.FypStudentEvaluationRemarks.FirstOrDefault(r =>
                r.studentEnrollID == dto.StudentEnrollID &&
                r.evaluatorID == dto.EvaluatorID &&
                r.sessionID == dto.SessionID
            );

            if (existing != null)
            {
                // 🔄 Update
                existing.remarks = dto.Remarks;
                existing.updatedAt = DateTime.Now;
            }
            else
            {
                // ➕ Insert
                var remark = new FypStudentEvaluationRemark
                {
                    studentEnrollID = dto.StudentEnrollID,
                    evaluatorID = dto.EvaluatorID,
                    sessionID = dto.SessionID,
                    remarks = dto.Remarks,
                    createdAt = DateTime.Now
                };

                db.FypStudentEvaluationRemarks.Add(remark);
            }

            db.SaveChanges();

            return Ok(new
            {
                Message = "Remarks saved successfully"
            });
        }
        public class StudentEvaluationRemarkDto
        {
            public int StudentEnrollID { get; set; }
            public string EvaluatorID { get; set; }
            public int SessionID { get; set; }
            public string Remarks { get; set; }
        }
        public class AssignParametersDto
        {
            public int MeetingId { get; set; }
            public List<int> ParameterIds { get; set; }
        }
        [HttpPost]
        [Route("calculate-final-fyp1")]
        public IHttpActionResult CalculateFinalFyp1([FromUri] bool includeSupervisorScore = false)
        {
            // Fetch latest session automatically
            var currentSession = db.Sessions.OrderByDescending(s => s.id).FirstOrDefault();
            if (currentSession == null) return BadRequest("No session found");

            var data = db.Fyp1StudentEvaluationMarks
                .Where(m => m.sessionID == currentSession.id)
                .ToList()
                .GroupBy(m => m.studentEnrollID)
                .Select(g =>
                {
                    var parameterGroups = g.GroupBy(x => x.parameterID);
                    decimal finalScore = 0;

                    foreach (var paramGroup in parameterGroups)
                    {
                        var parameter = db.Fyp1EvaluationParameters.Find(paramGroup.Key);
                        if (parameter == null) continue;

                        var subParamGroups = paramGroup.GroupBy(x => x.subParameterID);
                        decimal parameterTotal = 0;

                        foreach (var subGroup in subParamGroups)
                        {
                            var subParam = db.Fyp1SubParameter.Find(subGroup.Key);

                            // Average percentage obtained across all evaluators
                            decimal avgPercentage = subGroup
                                .Average(x => (x.maxMarks ?? 0) == 0 ? 0m : ((x.obtainedMarks ?? 0m) / (x.maxMarks ?? 1m)) * 100m);

                            if (subParam != null)
                            {
                                // Logic: (Score %) * (Sub-parameter Weightage) / 100
                                parameterTotal += (avgPercentage * (decimal)(subParam.percentage ?? 0)) / 100m;
                            }
                            else
                            {
                                parameterTotal += avgPercentage;
                            }
                        }

                        // Apply the main parameter weightage
                        finalScore += (parameterTotal * (decimal)(parameter.percentage ?? 0)) / 100m;
                    }

                    // 🔹 Incorporate Supervisor Score if enabled (80% Director, 20% Supervisor)
                    if (includeSupervisorScore)
                    {
                        var enrollment = db.Enrollments.FirstOrDefault(e => e.id == g.Key);
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

                    return new
                    {
                        EnrollmentID = g.Key,
                        SessionID = currentSession.id,
                        FinalScore = Math.Round(finalScore, 2),
                        Grade = GetGrade((double)finalScore)
                    };
                })
                .ToList();

            foreach (var r in data)
            {
                var enrollment = db.Enrollments.FirstOrDefault(e => e.id == r.EnrollmentID && e.subject == "FYP-1");
                if (enrollment != null) enrollment.grade = r.Grade;
            }
            db.SaveChanges();
            return Ok(data);
        }





        [HttpGet]
        [Route("evaluation-panel/{meetingId}")]
        public IHttpActionResult GetEvaluationPanel(int meetingId)
        {
            var meeting = db.ComiteeMeetings.Find(meetingId);
            if (meeting == null) return NotFound();

            var parameterIds = db.MeetingParameterMappings
                .Where(x => x.meetingID == meetingId)
                .Select(x => x.parameterID)
                .ToList();

            var allSubParams = db.Fyp1SubParameter
                .Where(s => parameterIds.Contains((int)s.parameterID))
                .ToList();

            var allEvaluators = db.Fyp1ParameterEvaluator
                .Where(e => parameterIds.Contains((int)e.parameterID))
                .ToList();

            var data = db.Fyp1EvaluationParameters
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
                        .ToList(),

                    evaluators = allEvaluators
                        .Where(e => e.parameterID == p.id)
                        .Select(e => e.evaluatorID)
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
    int meetingId,
    int sessionId)
        {

            // 1️⃣ Fetch all evaluation marks for this student & meeting
            var marks = db.Fyp1StudentEvaluationMarks
                .Where(x =>
                    x.studentEnrollID == studentId &&
                    x.meetingID == meetingId &&
                    x.sessionID == sessionId)
                .ToList();

            if (!marks.Any())
                return BadRequest("No evaluation found");

            // 2️⃣ Group by Parameter
            var parameterScores = marks
                .GroupBy(x => x.parameterID)
                .Select(g =>
                {
                    var parameter = db.Fyp1EvaluationParameters
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

            return Ok(new FinalEvaluationResultDto
            {
                StudentId = studentId,
                TotalObtained = System.Math.Round(finalScore, 2),
                TotalPercentage = totalPercentage,
                Grade = grade
            });

        }


        //[HttpPost]
        //[Route("calculate-final-fyp1")]
        //public IHttpActionResult CalculateFinalFyp1()
        //{
        //    var data = db.Fyp1StudentEvaluationMarks
        //        .ToList()
        //        .GroupBy(m => new { m.studentEnrollID, m.sessionID })
        //        .Select(g =>
        //        {
        //            var parameterGroups = g.GroupBy(x => x.parameterID);

        //            decimal finalScore = 0;

        //            foreach (var paramGroup in parameterGroups)
        //            {
        //                var parameter = db.Fyp1EvaluationParameters
        //                    .FirstOrDefault(p => p.id == paramGroup.Key);

        //                if (parameter == null) continue;

        //                decimal obtained = paramGroup.Sum(x => x.obtainedMarks ?? 0);
        //                decimal max = paramGroup.Sum(x => x.maxMarks ?? 0);

        //                if (max == 0) continue;

        //                decimal paramScore = (obtained / max) * (decimal)parameter.percentage;

        //                finalScore += paramScore;
        //            }

        //            return new
        //            {
        //                EnrollmentID = g.Key.studentEnrollID,
        //                SessionID = g.Key.sessionID,
        //                FinalScore = Math.Round(finalScore, 2),
        //                Grade = GetGrade((double)finalScore)
        //            };
        //        })
        //        .ToList();

        //    // ✅ SAVE INTO ENROLLMENT
        //    foreach (var r in data)
        //    {
        //        var enrollment = db.Enrollments
        //            .FirstOrDefault(e =>
        //                e.id == r.EnrollmentID &&
        //                e.sessionID == r.SessionID &&
        //                e.subject == "FYP-1"
        //            );

        //        if (enrollment != null)
        //        {
        //            enrollment.grade = $"{r.Grade}";
        //        }
        //    }

        //    db.SaveChanges();

        //    return Ok(data);
        //}
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
        [HttpGet]
        [Route("available-criteria/{sessionId}")]
        public IHttpActionResult GetAvailableCriteria(int sessionId)
        {
            var criteria = db.Fyp1EvaluationParameters
                .Where(p => p.sessionID == sessionId)
                .Select(p => new
                {
                    p.id,
                    p.name,
                    p.percentage,

                    // optional: include sub-criteria if needed in UI
                    subParameters = db.Fyp1SubParameter
                        .Where(s => s.parameterID == p.id)
                        .Select(s => new
                        {
                            s.id,
                            s.name,

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

            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new
            {

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
                        .Where(e => e.studentID == gm.studentID && e.sessionID == list.id && e.subject == "FYP-1")
                        .Select(e => e.id)
                        .FirstOrDefault(),

                    // ✅ Grade
                    Grade = db.Enrollments
                        .Where(e => e.studentID == gm.studentID && e.sessionID == list.id && e.subject == "FYP-1")
                        .Select(e => e.grade)
                        .FirstOrDefault(),

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
        [Route("save-or-update")]
        public IHttpActionResult SaveOrUpdateRemark(FypStudentEvaluationRemark model)
        {
            if (model == null)
                return BadRequest("Invalid data");

            var existing = db.FypStudentEvaluationRemarks.FirstOrDefault(r =>
                r.studentEnrollID == model.studentEnrollID &&
                r.evaluatorID == model.evaluatorID &&
                r.sessionID == model.sessionID &&
                r.meetingID == model.meetingID
            );

            if (existing != null)
            {
                // 🔁 UPDATE
                existing.remarks = model.remarks;
                existing.updatedAt = DateTime.Now;
            }
            else
            {
                // ➕ INSERT
                model.createdAt = DateTime.Now;
                db.FypStudentEvaluationRemarks.Add(model);
            }

            db.SaveChanges();

            return Ok(new { success = true });
        }
        [HttpGet]
        [Route("get-all-remarks/{enrollId}/{sessionId}")]
        public IHttpActionResult GetAllRemarks(int enrollId, int sessionId)
        {
            var data = db.FypStudentEvaluationRemarks
                .Where(x => x.studentEnrollID == enrollId && x.sessionID == sessionId)
                .Select(x => new
                {
                    x.remarks,
                    x.evaluatorID,
                    evaluatorName = db.Users
                        .Where(u => u.id == x.evaluatorID)
                        .Select(u => u.name)
                        .FirstOrDefault(),
                    x.createdAt
                }).ToList();

            return Ok(data);
        }


        [HttpPost]
        [Route("update-evaluation-marks")]
        public IHttpActionResult UpdateEvaluationMarks(List<UpdateEvaluationMarksDto> dtos)
        {
            foreach (var dto in dtos)
            {
                var record = db.Fyp1StudentEvaluationMarks.FirstOrDefault(x =>
                    x.studentEnrollID == dto.EnrollmentID &&
                    x.meetingID == dto.MeetingID &&
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
                    db.Fyp1StudentEvaluationMarks.Add(new Fyp1StudentEvaluationMarks
                    {
                        studentEnrollID = dto.EnrollmentID, // ✅ FIXED
                        meetingID = dto.MeetingID,
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
        [Route("get-saved-marks/{meetingId}/{parameterId}/{evaluatorId}")]
        public IHttpActionResult GetSavedMarks(int meetingId, int parameterId, string evaluatorId)
        {
            try
            {
                var marks = db.Fyp1StudentEvaluationMarks
                    .Where(m => m.meetingID == meetingId && 
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
        [Route("student-evaluation-history/{enrollmentId}")]
        public IHttpActionResult GetStudentEvaluationHistory(int enrollmentId)
        {
            try
            {
                var enrollment = db.Enrollments.FirstOrDefault(e => e.id == enrollmentId);
                if (enrollment == null)
                    return BadRequest("Student enrollment not found");

                var studentId = enrollment.studentID;
                var currentSession = db.Sessions.OrderByDescending(s => s.id).FirstOrDefault();
                if (currentSession == null)
                    return BadRequest("No active session found");

                var groupMember = db.GroupMembers.FirstOrDefault(gm => gm.studentID == studentId);
                if (groupMember == null)
                    return BadRequest("Student group not found");

                int groupId = (int)groupMember.groupID;

                // ==========================================
                // 1. SUPERVISOR HISTORY
                // ==========================================
                var supervisorHistory = (from t in db.Tasks
                                         join te in db.TaskEvaluations on t.id equals te.taskID into teJoin
                                         from eval in teJoin.DefaultIfEmpty()
                                         where t.groupID == groupId && (t.studentID == null || t.studentID == studentId)
                                         orderby t.dueDate descending
                                         select new
                                         {
                                             TaskTitle = t.title,
                                             DueDate = t.dueDate,
                                             Status = t.taskStatus,
                                             ProgressStatus = eval != null ? eval.progressStatus : "Initial",
                                             Score = eval != null ? (int?)eval.score : null,
                                             Remarks = eval != null ? eval.taskRemarks : "No remarks entered"
                                         }).ToList();

                // ==========================================
                // 2. COMMITTEE HISTORY
                // ==========================================
                var committeeFyp1 = (from m in db.Fyp1StudentEvaluationMarks
                                     where m.studentEnrollID == enrollmentId
                                     select new
                                     {
                                         MeetingTitle = db.ComiteeMeetings.Where(cm => cm.id == m.meetingID).Select(cm => cm.title).FirstOrDefault() ?? "Committee Meeting",
                                         ParameterName = db.Fyp1EvaluationParameters.Where(p => p.id == m.parameterID).Select(p => p.name).FirstOrDefault() ?? "Evaluation Parameter",
                                         SubParameterName = db.Fyp1SubParameter.Where(sp => sp.id == m.subParameterID).Select(sp => sp.name).FirstOrDefault() ?? "Sub Parameter",
                                         ObtainedMarks = m.obtainedMarks,
                                         MaxMarks = m.maxMarks,
                                         Evaluator = db.Users.Where(u => u.id == m.evaluatorID).Select(u => u.name).FirstOrDefault() ?? m.evaluatorID,
                                         Remarks = db.FypStudentEvaluationRemarks.Where(r => r.studentEnrollID == enrollmentId && r.meetingID == m.meetingID && r.evaluatorID == m.evaluatorID).Select(r => r.remarks).FirstOrDefault() ?? "No remarks entered"
                                     }).ToList();

                var committeeFyp2 = (from m in db.Fyp2StudentEvaluationMarks
                                     where m.studentEnrollID == enrollmentId
                                     select new
                                     {
                                         MeetingTitle = "FYP-2 Evaluation",
                                         ParameterName = db.Fyp2EvaluationParameters.Where(p => p.id == m.parameterID).Select(p => p.name).FirstOrDefault() ?? "Evaluation Parameter",
                                         SubParameterName = db.Fyp2SubParameter.Where(sp => sp.id == m.subParameterID).Select(sp => sp.name).FirstOrDefault() ?? "Sub Parameter",
                                         ObtainedMarks = m.obtainedMarks,
                                         MaxMarks = m.maxMarks,
                                         Evaluator = db.Users.Where(u => u.id == m.evaluatorID).Select(u => u.name).FirstOrDefault() ?? m.evaluatorID,
                                         Remarks = db.Fyp2StudentEvaluationRemarks.Where(r => r.studentEnrollID == enrollmentId && r.evaluatorID == m.evaluatorID).Select(r => r.remarks).FirstOrDefault() ?? "No remarks entered"
                                     }).ToList();

                var committeeHistory = committeeFyp1.Cast<object>().Concat(committeeFyp2.Cast<object>()).ToList();

                return Ok(new
                {
                    supervisorHistory,
                    committeeHistory
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        public class UpdateEvaluationMarksDto
        {
            public int EnrollmentID { get; set; }   // ✅ FIXED
            public int MeetingID { get; set; }
            public int ParameterID { get; set; }
            public int SubParameterID { get; set; }
            public string EvaluatorID { get; set; }
            public decimal ObtainedMarks { get; set; }
            public decimal MaxMarks { get; set; }
            public int SessionID { get; set; }
        }
        public class FinalEvaluationResultDto
        {
            public int StudentId { get; set; }
            public decimal TotalObtained { get; set; }
            public decimal TotalPercentage { get; set; }
            public string Grade { get; set; }
        }

        //        [HttpGet, Route("")]
        //        public IHttpActionResult GetAll() => Ok( db.FYP1Score.ToList());

        //        [HttpGet, Route("{id}")]
        //        public IHttpActionResult Get(int id)
        //        {
        //            var s =  db.FYP1Score.Find(id);
        //            if (s == null) return NotFound();
        //            return Ok(s);
        //        }

        //        [HttpPost, Route("")]
        //        public IHttpActionResult Create([FromBody] FYP1Score score)
        //        {
        //            if (!ModelState.IsValid) return BadRequest(ModelState);
        //            db.FYP1Score.Add(score);
        //             db.SaveChanges();
        //            return Ok(score);
        //        }


        //        [HttpGet, Route("student/{groupMemberId}/status")]
        //        public   IHttpActionResult GetStudentStatus(int groupMemberId)
        //        {
        //            var scores =   db.FYP1Score.Where(s => s.groupMemberID == groupMemberId).ToList ();
        //            if (!scores.Any()) return Ok(new { evaluated = false });

        //            var avg = scores.Average(s => s.score);
        //            bool pass = avg >= 50;
        //            return Ok(new { evaluated = true, average = avg, pass });
        //        }


        //        [HttpPut, Route("{id}")]
        //        public   IHttpActionResult Update(int id, [FromBody] FYP1Score updated)
        //        {
        //            if (id != updated.id) return BadRequest("Id mismatch");
        //            db.Entry(updated).State = EntityState.Modified;
        //              db.SaveChanges ();
        //            return Ok(updated);
        //        }



        //        [HttpDelete, Route("{id}")]
        //        public   IHttpActionResult Delete(int id)
        //        {
        //            var s =   db.FYP1Score.Find (id);
        //            if (s == null) return NotFound();
        //            db.FYP1Score.Remove(s);
        //              db.SaveChanges ();
        //            return Ok();
        //        }


        //        [HttpGet]
        //        [Route("evaluation-data/{meetingQueueId}")]
        //        public IHttpActionResult GetEvaluationPanelData(int meetingQueueId, string parameterName, int currentSessionId)
        //        {

        //            var groupId = db.MeetingQueues
        //                .Where(mq => mq.id == meetingQueueId)
        //                .Join(db.GroupSchedules,
        //                        mq => mq.scheduleID,
        //                        gs => gs.id,
        //                        (mq, gs) => gs.groupID)
        //                .FirstOrDefault();

        //            if (!groupId.HasValue) return NotFound(); 

        //            var parameterId = db.Fyp1EvaluationParameters
        //                .Where(p => p.name == parameterName)
        //                .Select(p => p.id)
        //                .FirstOrDefault();

        //            if (parameterId == 0) return NotFound();

        //            var studentScores = db.GroupMembers
        //                .Where(gm => gm.groupID == groupId.Value)
        //                .Join(db.Students,
        //                        gm => gm.studentID,
        //                        s => s.regNum,
        //                        (gm, s) => new
        //                        {
        //                            GroupMember = gm,
        //                            StudentName = s.name
        //                        })
        //                .Select(x => new StudentScoreDto
        //                {
        //                    GroupMemberId = x.GroupMember.id, 
        //                    StudentName = x.StudentName,
        //                    ExistingScore = db.FYP1Score
        //                        .Where(sc => sc.groupMemberID == x.GroupMember.id &&
        //                                     sc.parameterID == parameterId &&
        //                                     sc.sessionID == currentSessionId)
        //                        .Select(sc => (int?)sc.score) 
        //                        .FirstOrDefault() ?? 0        
        //                }).ToList();

        //            return Ok(new EvaluationPanelDto
        //            {
        //                ParameterId = parameterId,
        //                ParameterName = parameterName,
        //                SessionId = currentSessionId,
        //                Students = studentScores
        //            });
        //        }


        //        [HttpPost]
        //        [Route("submit-scores")]
        //        public IHttpActionResult SubmitFyp1Scores([FromBody] ScoreSubmissionDto input)
        //        {
        //            if (input == null || input.Scores == null || !ModelState.IsValid)
        //            {
        //                return BadRequest("Invalid input or missing scores.");
        //            }

        //            foreach (var scoreInput in input.Scores)
        //            {
        //                var existingScore = db.FYP1Score
        //                    .Where(s => s.groupMemberID == scoreInput.GroupMemberId &&
        //                                s.parameterID == input.ParameterId &&
        //                                s.sessionID == input.SessionId &&
        //                                s.evaluatorID == input.EvaluatorId)
        //                    .FirstOrDefault();

        //                if (existingScore != null)
        //                {
        //                    existingScore.score = scoreInput.Score;
        //                }
        //                else
        //                {
        //                    db.FYP1Score.Add(new FYP1Score
        //                    {
        //                        evaluatorID = input.EvaluatorId,
        //                        parameterID = input.ParameterId,
        //                        sessionID = input.SessionId,
        //                        score = scoreInput.Score,
        //                        groupMemberID = (int)scoreInput.GroupMemberId
        //                    });
        //                }
        //            }

        //            db.SaveChanges();
        //            return Ok("Scores submitted successfully.");
        //        }

        //        protected override void Dispose(bool disposing)
        //        {
        //            if (disposing) db.Dispose();
        //            base.Dispose(disposing);
        //        }
        //    }


        //    public class ScoreSubmissionDto
        //    {
        //        public string EvaluatorId { get; set; }
        //        public int SessionId { get; set; }
        //        public int ParameterId { get; set; }
        //        public List<ScoreInputDto> Scores { get; set; }
        //    }

        //    public class EvaluationPanelDto
        //    {
        //        public int? ParameterId { get; set; }
        //        public string ParameterName { get; set; }
        //        public int? SessionId { get; set; }
        //        public List<StudentScoreDto> Students { get; set; }
        //    }

        //    public class StudentScoreDto
        //    {
        //        public int? GroupMemberId { get; set; }
        //        public string StudentName { get; set; F
        //        public int ExistingScore { get; set; }
        //    }

        //    public class ScoreInputDto
        //    {
        //        public int? GroupMemberId { get; set; }
        //        public int Score { get; set; }
        //    }
    }
}