using System.Collections.Generic;
using System.Data.Entity;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Net.Http;
using ProgressMonitoringProject.Models;
using Microsoft.SqlServer.Server;
using System.Data.Entity.Core.Common.CommandTrees.ExpressionBuilder;
using Microsoft.Ajax.Utilities;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/committee-meetings")]
    public class CommitteeMeetingsController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        //        [HttpGet, Route("groups/{meetingId}")]
        //        public IHttpActionResult GetGroupsByCommitteeMeeting(int meetingId)
        //        {
        //            var groups = db.GroupSchedules
        //                .Where(gs => gs.comiteeMeetingID == meetingId)
        //                .Select(gs => new
        //                {
        //                    gs.id,
        //                    group = new
        //                    {
        //                        gs.groupID,
        //                        groupName = gs.ProjectGroup.id,
        //                        supervisorId = gs.ProjectGroup.supervisorID,
        //                        createdBy = gs.ProjectGroup.createdBy,
        //                        projectId = gs.ProjectGroup.projectID
        //                    },
        //                    meetingSchedule = new
        //                    {
        //                        gs.comiteeMeetingID,
        //                        gs.ComiteeMeeting.meetingDescription,
        //                        gs.ComiteeMeeting.startDate,
        //                        gs.ComiteeMeeting.endDate,
        //                        gs.ComiteeMeeting.startTime,
        //                        gs.ComiteeMeeting.endTime,
        //                        gs.ComiteeMeeting.venue,
        //                        gs.ComiteeMeeting.selectedDays,
        //                        gs.ComiteeMeeting.isGraded,
        //                        gs.ComiteeMeeting.isFileRequired
        //                    },
        //                    queue = db.MeetingQueues
        //                        .Where(q => q.scheduleID == gs.id)
        //                        .Select(q => new
        //                        {
        //                            q.id,
        //                            q.meetingDate,
        //                            q.meetingTime,
        //                            q.status 
        //                        }).FirstOrDefault(),
        //                    students = gs.ProjectGroup.GroupMembers
        //                        .Select(gm => new
        //                        {
        //                            gm.studentID,
        //                            studentName = gm.Student.name,
        //                            gm.requestStatus
        //                        }).ToList()
        //                })
        //                .ToList();

        //            if (!groups.Any()) return NotFound();

        //            return Ok(groups);
        //        }


        //        [HttpGet, Route("groups/inprogress/{meetingId}")]
        //        public IHttpActionResult GetInProgressGroups(int meetingId)
        //        {
        //            var groups = db.GroupSchedules
        //                .Where(gs => gs.comiteeMeetingID == meetingId)
        //                .Where(gs => db.MeetingQueues.Any(q => q.scheduleID == gs.id && q.status == "In-Progress"))
        //                .Select(gs => new
        //                {
        //                    gs.id,
        //                    group = new
        //                    {
        //                        gs.groupID,
        //                        groupName = gs.ProjectGroup.id,
        //                        supervisorId = gs.ProjectGroup.supervisorID
        //                    },
        //                    students = gs.ProjectGroup.GroupMembers
        //                        .Select(gm => new
        //                        {
        //                            gm.studentID,
        //                            studentName = gm.Student.name,
        //                            gm.requestStatus
        //                        }).ToList()
        //                }).ToList();

        //            if (!groups.Any()) return NotFound();

        //            return Ok(groups);
        //        }


        //        [HttpGet, Route("groups/waiting/{meetingId}")]
        //        public IHttpActionResult GetWaitingGroups(int meetingId)
        //        {
        //            var groups = db.GroupSchedules
        //                .Where(gs => gs.comiteeMeetingID == meetingId)
        //                .Where(gs => db.MeetingQueues.Any(q => q.scheduleID == gs.id && q.status == "Waiting"))
        //                .Select(gs => new
        //                {
        //                    gs.id,
        //                    group = new
        //                    {
        //                        gs.groupID,
        //                        groupName = gs.ProjectGroup.id,
        //                        supervisorId = gs.ProjectGroup.supervisorID
        //                    },
        //                    students = gs.ProjectGroup.GroupMembers
        //                        .Select(gm => new
        //                        {
        //                            gm.studentID,
        //                            studentName = gm.Student.name,
        //                            gm.requestStatus
        //                        }).ToList()
        //                }).ToList();

        //            if (!groups.Any()) return NotFound();

        //            return Ok(groups);
        //        }

        //               [HttpGet, Route("group/{groupScheduleId}/students")]
        //        public IHttpActionResult GetStudentsForInProgressGroup(int groupScheduleId)
        //        {
        //            var group = db.GroupSchedules
        //                .Where(gs => gs.id == groupScheduleId)
        //                .Where(gs => db.MeetingQueues.Any(q => q.scheduleID == gs.id && q.status == "In-Progress"))
        //                .Select(gs => new
        //                {
        //                    gs.id,
        //                    groupID = gs.groupID,
        //                    students = gs.ProjectGroup.GroupMembers
        //                        .Select(gm => new
        //                        {
        //                            gm.studentID,
        //                            studentName = gm.Student.name,
        //                            gm.requestStatus
        //                        }).ToList()
        //                }).FirstOrDefault();

        //            if (group == null) return NotFound();

        //            return Ok(group);
        //        }

        //        [HttpPut, Route("attendance/update")]
        //        public IHttpActionResult UpdateAttendance(int scheduleId, int studentId, bool isPresent, string remarks)
        //        {
        //            var attendance = db.MeetingAttendances
        //                .FirstOrDefault(a => a.scheduleID == scheduleId && a.studentID == studentId);

        //            if (attendance == null)
        //            {
        //                attendance = new MeetingAttendance
        //                {
        //                    scheduleID = scheduleId,
        //                    studentID = studentId,
        //                    attendance = isPresent,
        //                    remarks = remarks
        //                };
        //                db.MeetingAttendances.Add(attendance);
        //            }
        //            else
        //            {
        //                attendance.attendance = isPresent;
        //                attendance.remarks = remarks;
        //            }

        //            db.SaveChanges();
        //            return Ok(new
        //            {
        //                Message = "Attendance updated successfully",
        //                scheduleId = scheduleId,
        //                studentId = studentId,
        //                isPresent = isPresent,
        //                remarks = remarks
        //            });
        //        }

        //        [HttpPut, Route("queue/attendance/update")]
        //        public IHttpActionResult UpdateQueueAttendance(int queueId, int memberId, bool isPresent)
        //        {
        //            var attendance = db.MeetingQueueAttendances
        //                .FirstOrDefault(a => a.meetingQueueID == queueId && a.memberID == memberId);

        //            if (attendance == null)
        //            {
        //                attendance = new MeetingQueueAttendance
        //                {
        //                    meetingQueueID = queueId,
        //                    memberID = memberId,
        //                    isPresent = isPresent
        //                };
        //                db.MeetingQueueAttendances.Add(attendance);
        //            }
        //            else
        //            {
        //                attendance.isPresent = isPresent;
        //            }

        //            db.SaveChanges();
        //            return Ok(new
        //            {
        //                Message = "Queue attendance updated successfully",
        //                queueId = queueId,
        //                memberId = memberId,
        //                isPresent = isPresent
        //            });
        //        }





        //        [HttpPost]
        //        [Route("remarks/{groupScheduleId}")]
        //        public async Task<IHttpActionResult> AddMemberRemarks(int groupScheduleId, [FromBody] List<MemberRemarksDto> remarksData)
        //        {
        //            if (remarksData == null || !remarksData.Any())
        //            {
        //                return BadRequest("Remarks data cannot be empty.");
        //            }

        //            try
        //            {
        //                foreach (var item in remarksData)
        //                {

        //                    var existingRecord = await db.MeetingAttendances
        //                        .FirstOrDefaultAsync(ma => ma.scheduleID == groupScheduleId &&
        //                                                   ma.studentID == item.GroupMemberId);

        //                    if (existingRecord != null)
        //                    {
        //                        existingRecord.remarks = item.Remarks;


        //                    }
        //                    else
        //                    {

        //                        var newAttendance = new MeetingAttendance
        //                        {
        //                            scheduleID = groupScheduleId,
        //                            studentID = item.GroupMemberId,
        //                            attendance = false,
        //                            remarks = item.Remarks
        //                        };
        //                        db.MeetingAttendances.Add(newAttendance);
        //                    }
        //                }

        //                await db.SaveChangesAsync();
        //                return Ok("Member remarks saved successfully.");
        //            }
        //            catch (Exception ex)
        //            {
        //                return InternalServerError(ex);
        //            }
        //        }

        //    }
        //    public class MemberRemarksDto
        //    {
        //        public int GroupMemberId { get; set; } 
        //        public string Remarks { get; set; }
        [HttpGet]
        [Route("meetings/{meetingId}")]
        public IHttpActionResult GetMeetings(int meetingId)
        {
            var meetings = db.ComiteeMeetings
                .Where(m => m.id == meetingId)
                .Select(m => new
                {
                    m.id,
                    m.meetingDescription,
                    m.startDate,
                    m.endDate,
                    m.startTime,
                    m.endTime,
                    m.venue,
                    days = m.selectedDays,
                    m.isGraded,
                    m.isFileRequired
                })
                .ToList();

            return Ok(meetings);
        }

        //    [HttpPost]
        //    [Route("schedule-meeting")]
        //    public IHttpActionResult ScheduleMeeting(ScheduleCommitteeMeetingDto model)
        //    {
        //        if (!ModelState.IsValid)
        //            return BadRequest("Invalid data");

        //        if (model.startDate > model.endDate)
        //            return BadRequest("Start date cannot be after end date");

        //        if (model.startTime >= model.endTime)
        //            return BadRequest("Start time must be before end time");

        //        var meeting = new ComiteeMeeting
        //        {
        //            meetingDescription = model.meetingDescription,
        //            startDate = model.startDate,
        //            endDate = model.endDate,
        //            startTime = model.startTime,
        //            endTime = model.endTime,
        //            venue = model.venue,
        //            selectedDays = string.Join(",", model.selectedDays), // SAVE AS CSV
        //            sessionID = model.sessionID,
        //            isGraded = model.isGraded,
        //            isFileRequired = model.isFileRequired
        //        };

        //        db.ComiteeMeetings.Add(meeting);
        //        db.SaveChanges();

        //        return Ok(new
        //        {
        //            message = "Committee meeting scheduled successfully",
        //            meetingId = meeting.id
        //        });



        //    }

        //}

        //[HttpPost]
        //[Route("mark-presented")]
        //public IHttpActionResult MarkPresented(int meetingId, int groupId)
        //{
        //    var record = db.MeetingGroupStatus
        //        .FirstOrDefault(x => x.meetingID == meetingId && x.groupID == groupId);

        //    if (record == null)
        //    {
        //        record = new MeetingGroupStatus
        //        {
        //            meetingID = meetingId,
        //            groupID = groupId,
        //            status = "Presented",
        //            presentationDate = DateTime.Now
        //        };

        //        db.MeetingGroupStatus.Add(record);
        //    }
        //    else
        //    {
        //        record.status = "Presented";
        //        record.presentationDate = DateTime.Now;
        //    }

        //    db.SaveChanges();

        //    return Ok("Marked as Presented");
        //}

        //[HttpGet]
        //[Route("get-daily-schedule/{meetingId}/{date}")]
        //public IHttpActionResult GetDailySchedule(int meetingId, DateTime date)
        //{
        //    var meeting = db.ComiteeMeetings.Find(meetingId);
        //    if (meeting == null)
        //        return NotFound();

        //    var totalMinutes =
        //        (meeting.endTime.Value - meeting.startTime.Value).TotalMinutes;

        //    var totalGroups = db.ProjectGroups
        //        .Where(g => g.createdSession == meeting.sessionID && g.isFinalized)
        //        .Count();

        //    var minutesPerGroup = totalMinutes / totalGroups;
        //    int groupsPerDay = (int)(totalMinutes / minutesPerGroup);

        //    // 1️⃣ Get Pending groups first
        //    var pendingGroups = db.MeetingGroupStatus
        //        .Where(x => x.meetingID == meetingId && x.status == "Pending")
        //        .Select(x => x.groupID)
        //        .ToList();

        //    var orderedGroups = db.ProjectGroups
        //        .Where(g => g.createdSession == meeting.sessionID && g.isFinalized)
        //        .OrderBy(g => g.Supervisor.name)
        //        .Select(g => g.id)
        //        .ToList();

        //    // Pending first
        //    var finalOrder = orderedGroups
        //        .Where(g => pendingGroups.Contains(g))
        //        .Concat(orderedGroups.Where(g => !pendingGroups.Contains(g)))
        //        .Take(groupsPerDay)
        //        .ToList();

        //    return Ok(new
        //    {




        [HttpGet]
        [Route("HeadMeetings")]
        public IHttpActionResult GetHeadMeetings()
        {
            var today = DateTime.Today;
            var now = DateTime.Now;

            // Auto-sync for both FYP phases
            var phases = new[] { "FYP-1", "FYP-2" };
            foreach (var p in phases)
            {
                var pending = db.GroupSchedules
                    .Where(m => m.meetingDate == today && m.type == p && m.Status != "Completed")
                    .OrderBy(m => m.estimatedTime)
                    .ToList();

                // PRO LOGIC: Always re-index if a meeting is live or overdue to support 'Sliding Queue' (adding up minutes)
                bool isInProgress = pending.Any(g => g.Status == "In-Progress");
                bool isOverdue = pending.Any() && pending[0].Status == "Waiting" && pending[0].estimatedTime <= now.TimeOfDay;

                if (isInProgress || isOverdue)
                {
                    ReindexQueue(p);
                }
            }
            db.SaveChanges();


            var meetings = db.GroupSchedules
                .Where(m => m.meetingDate == today)
                .ToList()
                .OrderBy(m => m.Status == "In-Progress" ? 0 : (m.Status == "Waiting" ? 1 : 2))
                .ThenBy(m => m.estimatedTime)
                .Select(m => new
                {
                    id = m.comiteeMeetingID,
                    scheduleId = m.id,
                    title = m.ComiteeMeeting.title,
                    date = m.meetingDate,
                    time = m.estimatedTime,
                    status = m.Status,
                    type = m.type,
                    phase = m.type, // e.g. FYP-1 or FYP-2
                    groupName = "Group " + m.groupID,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == m.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    members = db.GroupMembers
                        .Where(gm => gm.groupID == m.groupID)
                        .Select(gm => gm.Student.name)
                        .ToList()
                })
                .ToList();

            return Ok(meetings);
        }

        //[Route("groups")]
        //public IHttpActionResult GetGroups()
        //{
        //    var data = (from t in db.Fyp2Task
        //                join e in db.Fyp2TaskEvaluation on t.id equals e.taskID into te
        //                from e in te.DefaultIfEmpty()
        //                select new
        //                {
        //                    id = t.groupID,
        //                    name = "Group " + t.groupID,
        //                    description = "", 
        //                    finalTask = t.taskDescription,
        //                    remarks = e.remarks
        //                }).ToList();

        //    return Ok(data);
        //}


        //[HttpPost]
        //[Route("assign-task")]
        //public IHttpActionResult AssignTask(Fyp2Task dto)
        //{
        //    if (string.IsNullOrEmpty(dto.taskDescription))
        //        return BadRequest("Task is required");

        //    // Check if task already exists for group
        //    var existing = db.Fyp2Task
        //        .FirstOrDefault(x => x.groupID == dto.groupID && x.sessionID == 2);

        //    if (existing != null)
        //    {
        //        existing.taskDescription = dto.taskDescription;
        //    }
        //    else
        //    {
        //        var task = new Fyp2Task
        //        {
        //            groupID = dto.groupID,
        //            sessionID = 2, // change if dynamic
        //            taskDescription = dto.taskDescription
        //        };

        //        db.Fyp2Task.Add(task);
        //    }

        //    db.SaveChanges();

        //    return Ok("Task Saved");
        //}







        //[HttpGet]
        //[Route("Getcriteria/{sessionId}")]
        //public IHttpActionResult GetCriteriaBySession(int sessionId)
        //{
        //    var data = db.Fyp1EvaluationParameters
        //        .Where(p => p.sessionID == sessionId)
        //        .Select(p => new 
        //        {
        //            id = p.id,
        //            name = p.name,
        //            percentage = p.percentage ?? 0,
        //            allowEvaluation = p.allowEvaluation ?? false,
        //            evaluators = p.Fyp1ParameterEvaluator
        //                .Select(e => e.evaluatorID)
        //                .ToList(),
        //            subParameters = p.Fyp1SubParameter
        //                .Select(s => new 
        //                {
        //                    id = s.id,
        //                    name = s.name,
        //                    percentage = s.percentage ?? 0
        //                })
        //                .ToList()
        //        })
        //        .ToList();

        //    return Ok(data);
        //}


        // ================= FYP-1 CRITERIA ENDPOINTS =================

        [HttpGet, Route("GetCriteriaFyp1/{sessionId}")]
        public IHttpActionResult GetCriteriaFyp1(int sessionId)
        {
            var data = db.Fyp1EvaluationParameters
                .Where(p => p.sessionID == sessionId)
                .ToList()
                .Select(p => new EvaluationCriteriaDto
                {
                    id = p.id,
                    name = p.name,
                    percentage = p.percentage ?? 0,
                    allowEvaluation = p.allowEvaluation ?? false,
                    evaluators = p.Fyp1ParameterEvaluator?.Select(e => e.evaluatorID).ToList() ?? new List<string>(),
                    subParameters = p.Fyp1SubParameter.Select(s => new SubParameterDto
                    {
                        id = s.id, // 👈 Send ID to frontend
                        name = s.name,
                        percentage = s.percentage ?? 0
                    }).ToList()
                }).ToList();
            return Ok(data);
        }

        [HttpPost, Route("EditCriteriaFyp1/{sessionId}")]
        public IHttpActionResult UpdateCriteriaFyp1(int sessionId, List<EvaluationCriteriaDto> model)
        {
            if (model == null || !model.Any()) return BadRequest("No data provided.");

            // 🛡️ Validate 100% Sum
            if (model.Sum(p => p.percentage) != 100)
                return BadRequest("Total percentage of parameters must be exactly 100%.");

            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    foreach (var p in model)
                    {
                        var param = db.Fyp1EvaluationParameters
                            .Include("Fyp1ParameterEvaluator").Include("Fyp1SubParameter")
                            .FirstOrDefault(x => x.id == p.id && x.sessionID == sessionId);

                        if (param == null) continue;

                        param.name = p.name;
                        param.percentage = p.percentage;
                        param.allowEvaluation = p.allowEvaluation;

                        // 🔄 1. Update Sub-Parameters (Intelligent Sync)
                        if (p.subParameters != null)
                        {
                            var incomingIds = p.subParameters.Where(s => s.id.HasValue && s.id > 0).Select(s => s.id.Value).ToList();
                            var toRemove = param.Fyp1SubParameter.Where(s => !incomingIds.Contains(s.id)).ToList();
                            if (toRemove.Any())
                            {
                                foreach (var subToRemove in toRemove)
                                {
                                    if (!db.Fyp1StudentEvaluationMarks.Any(m => m.subParameterID == subToRemove.id))
                                    {
                                        db.Fyp1SubParameter.Remove(subToRemove);
                                    }
                                }
                            }

                            foreach (var subDto in p.subParameters)
                            {
                                if (subDto.id.HasValue && subDto.id > 0)
                                {
                                    // Update existing
                                    var existingSub = param.Fyp1SubParameter.FirstOrDefault(s => s.id == subDto.id);
                                    if (existingSub != null)
                                    {
                                        existingSub.name = subDto.name;
                                        existingSub.percentage = subDto.percentage;
                                    }
                                }
                                else
                                {
                                    // Add new
                                    db.Fyp1SubParameter.Add(new Fyp1SubParameter
                                    {
                                        parameterID = param.id,
                                        name = subDto.name,
                                        percentage = subDto.percentage
                                    });
                                }
                            }
                        }

                        // 🔄 2. Update Evaluators
                        db.Fyp1ParameterEvaluator.RemoveRange(param.Fyp1ParameterEvaluator);
                        if (p.allowEvaluation && p.evaluators != null && p.evaluators.Any())
                        {
                            foreach (string ev in p.evaluators)
                            {
                                if (!db.Users.Any(u => u.id == ev))
                                    continue;

                                db.Fyp1ParameterEvaluator.Add(new Fyp1ParameterEvaluator
                                {
                                    parameterID = param.id,
                                    evaluatorID = ev
                                });
                            }
                        }
                    }
                    db.SaveChanges();
                    transaction.Commit();
                    return Ok("Updated Successfully ✅");
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    return BadRequest(ex.InnerException?.InnerException?.Message ?? ex.Message);
                }
            }
        }


        // ================= FYP-2 CRITERIA ENDPOINTS =================

        [HttpGet, Route("GetCriteriaFyp2/{sessionId}")]
        public IHttpActionResult GetCriteriaFyp2(int sessionId)
        {
            var data = db.Fyp2EvaluationParameters
                .Where(p => p.sessionID == sessionId)
                .ToList()
                .Select(p => new EvaluationCriteriaDto
                {
                    id = p.id,
                    name = p.name,
                    percentage = (int)(p.percentage ?? 0),
                    allowEvaluation = false,
                    evaluators = new List<string>(),
                    subParameters = p.Fyp2SubParameter.Select(s => new SubParameterDto
                    {
                        id = s.id, // 👈 Send ID to frontend
                        name = s.name,
                        percentage = (int)(s.percentage ?? 0)
                    }).ToList()
                }).ToList();
            return Ok(data);
        }

        [HttpPost, Route("EditCriteriaFyp2/{sessionId}")]
        public IHttpActionResult UpdateCriteriaFyp2(int sessionId, List<EvaluationCriteriaDto> model)
        {
            if (model == null || !model.Any()) return BadRequest("No data provided.");

            // 🛡️ Validate 100% Sum
            if (model.Sum(p => p.percentage) != 100)
                return BadRequest("Total percentage of parameters must be exactly 100%.");

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

                        // 🔄 Update Sub-Parameters (Intelligent Sync)
                        if (p.subParameters != null)
                        {
                            var incomingIds = p.subParameters.Where(s => s.id.HasValue && s.id > 0).Select(s => s.id.Value).ToList();
                            var toRemove = param.Fyp2SubParameter.Where(s => !incomingIds.Contains(s.id)).ToList();
                            if (toRemove.Any())
                            {
                                foreach (var subToRemove in toRemove)
                                {
                                    if (!db.Fyp2StudentEvaluationMarks.Any(m => m.subParameterID == subToRemove.id))
                                    {
                                        db.Fyp2SubParameter.Remove(subToRemove);
                                    }
                                }
                            }

                            foreach (var subDto in p.subParameters)
                            {
                                if (subDto.id.HasValue && subDto.id > 0)
                                {
                                    // Update existing
                                    var existingSub = param.Fyp2SubParameter.FirstOrDefault(s => s.id == subDto.id);
                                    if (existingSub != null)
                                    {
                                        existingSub.name = subDto.name;
                                        existingSub.percentage = subDto.percentage;
                                    }
                                }
                                else
                                {
                                    // Add new
                                    db.Fyp2SubParameter.Add(new Fyp2SubParameter
                                    {
                                        parameterID = param.id,
                                        name = subDto.name,
                                        percentage = subDto.percentage
                                    });
                                }
                            }
                        }
                    }
                    db.SaveChanges();
                    transaction.Commit();
                    return Ok("FYP-2 Criteria Updated Successfully ✅");
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    return BadRequest(ex.InnerException?.InnerException?.Message ?? ex.Message);
                }
            }
        }



        //[HttpGet]
        //[Route("Getcriteria/{sessionId}")]
        //public IHttpActionResult GetCriteriaBySession(int sessionId)
        //{
        //    try
        //    {
        //        // 🟢 Fetch FYP-1 Parameters
        //        var fyp1 = db.Fyp1EvaluationParameters
        //            .Where(p => p.sessionID == sessionId)
        //            .ToList() // Execute query first to avoid complex LINQ issues
        //            .Select(p => new EvaluationCriteriaDto
        //            {
        //                id = p.id,
        //                name = p.name,
        //                percentage = p.percentage ?? 0,
        //                allowEvaluation = p.allowEvaluation ?? false,
        //                evaluators = p.Fyp1ParameterEvaluator?.Select(e => e.evaluatorID).ToList() ?? new List<string>(),
        //                subParameters = p.Fyp1SubParameter?.Select(s => new SubParameterDto
        //                {
        //                    name = s.name,
        //                    percentage = s.percentage ?? 0
        //                }).ToList() ?? new List<SubParameterDto>()
        //            }).ToList();

        //        // 🔵 Fetch FYP-2 Parameters
        //        var fyp2 = db.Fyp2EvaluationParameters
        //            .Where(p => p.sessionID == sessionId)
        //            .ToList()
        //            .Select(p => new EvaluationCriteriaDto
        //            {
        //                id = p.id,
        //                name = p.name,
        //                percentage = (int)(p.percentage ?? 0),
        //                allowEvaluation = false, // FYP-2 schema doesn't have this
        //                evaluators = new List<string>(),
        //                subParameters = p.Fyp2SubParameter?.Select(s => new SubParameterDto
        //                {
        //                    name = s.name,
        //                    percentage = (int)(s.percentage ?? 0)
        //                }).ToList() ?? new List<SubParameterDto>()
        //            }).ToList();

        //        var all = fyp1.Concat(fyp2).ToList();
        //        return Ok(all);
        //    }
        //    catch (Exception ex)
        //    {
        //        // Return full error message for debugging
        //        return BadRequest("Error loading criteria: " + ex.Message + (ex.InnerException != null ? " -> " + ex.InnerException.Message : ""));
        //    }
        //}


        //[HttpPost]
        //[Route("Editcriteria/{sessionId}")]
        //public IHttpActionResult UpdateCriteria(int sessionId, List<EvaluationCriteriaDto> model)
        //{
        //    using (var transaction = db.Database.BeginTransaction())
        //    {
        //        try
        //        {
        //            foreach (var p in model)
        //            {
        //                var param = db.Fyp1EvaluationParameters
        //                    .Include("Fyp1ParameterEvaluator")
        //                    .Include("Fyp1SubParameter")
        //                    .FirstOrDefault(x => x.id == p.id && x.sessionID == sessionId);

        //                if (param == null) continue;

        //                param.name = p.name;
        //                param.percentage = p.percentage;
        //                param.allowEvaluation = p.allowEvaluation;

        //                // 🔴 Remove old evaluators
        //                db.Fyp1ParameterEvaluator.RemoveRange(param.Fyp1ParameterEvaluator);

        //                // ✅ Add new evaluators
        //                if (p.allowEvaluation && p.evaluators != null && p.evaluators.Any())
        //                {
        //                    foreach (string ev in p.evaluators)
        //                    {
        //                        // optional safety check
        //                        if (!db.Users.Any(u => u.id == ev))
        //                            continue;

        //                        db.Fyp1ParameterEvaluator.Add(new Fyp1ParameterEvaluator
        //                        {
        //                            parameterID = param.id,
        //                            evaluatorID = ev   // ✅ STRING MATCH
        //                        });
        //                    }
        //                }

        //                // 🔴 Remove old sub parameters
        //                db.Fyp1SubParameter.RemoveRange(param.Fyp1SubParameter);

        //                // ✅ Add updated sub parameters
        //                if (p.subParameters != null)
        //                {
        //                    foreach (var sub in p.subParameters)
        //                    {
        //                        db.Fyp1SubParameter.Add(new Fyp1SubParameter
        //                        {
        //                            parameterID = param.id,
        //                            name = sub.name,
        //                            percentage = sub.percentage
        //                        });
        //                    }
        //                }
        //            }

        //            db.SaveChanges();
        //            transaction.Commit();
        //            return Ok("Criteria updated successfully");
        //        }
        //        catch (Exception ex)
        //        {
        //            transaction.Rollback();
        //            return InternalServerError(ex);
        //        }
        //    }
        //}


        //[HttpPost]
        //[Route("Editcriteria/{sessionId}")]
        //public IHttpActionResult UpdateCriteria(int sessionId, List<EvaluationCriteriaDto> model)
        //{
        //    if (model == null || !model.Any()) return BadRequest("No criteria provided.");
        //    // 🛡️ 1. Validate Main Parameters Total
        //    var totalPercentage = model.Sum(p => p.percentage);
        //    if (totalPercentage != 100)
        //    {
        //        return BadRequest($"Total percentage of all parameters must be exactly 100%. Current total: {totalPercentage}%");
        //    }
        //    // 🛡️ 2. Validate Sub-Parameters Total
        //    foreach (var p in model)
        //    {
        //        if (p.subParameters != null && p.subParameters.Any())
        //        {
        //            var subTotal = p.subParameters.Sum(s => s.percentage);
        //            if (subTotal != 100)
        //            {
        //                return BadRequest($"Sub-parameters for '{p.name}' must sum to exactly 100%. Current total: {subTotal}%");
        //            }
        //        }
        //    }
        //    using (var transaction = db.Database.BeginTransaction())
        //    {
        //        try
        //        {
        //            foreach (var p in model)
        //            {
        //                // 🟢 Try FYP-1 Tables First
        //                var paramFyp1 = db.Fyp1EvaluationParameters
        //                    .Include("Fyp1ParameterEvaluator")
        //                    .Include("Fyp1SubParameter")
        //                    .FirstOrDefault(x => x.id == p.id && x.sessionID == sessionId);
        //                if (paramFyp1 != null)
        //                {
        //                    paramFyp1.name = p.name;
        //                    paramFyp1.percentage = p.percentage;
        //                    paramFyp1.allowEvaluation = p.allowEvaluation;
        //                    // Update Evaluators
        //                    db.Fyp1ParameterEvaluator.RemoveRange(paramFyp1.Fyp1ParameterEvaluator);
        //                    if (p.allowEvaluation && p.evaluators != null)
        //                    {
        //                        foreach (string ev in p.evaluators)
        //                        {
        //                            db.Fyp1ParameterEvaluator.Add(new Fyp1ParameterEvaluator { parameterID = paramFyp1.id, evaluatorID = ev });
        //                        }
        //                    }
        //                    // Update Sub-Parameters
        //                    db.Fyp1SubParameter.RemoveRange(paramFyp1.Fyp1SubParameter);
        //                    if (p.subParameters != null)
        //                    {
        //                        foreach (var sub in p.subParameters)
        //                        {
        //                            db.Fyp1SubParameter.Add(new Fyp1SubParameter { parameterID = paramFyp1.id, name = sub.name, percentage = sub.percentage });
        //                        }
        //                    }
        //                }
        //                else
        //                {
        //                    // 🔵 Try FYP-2 Tables if not found in FYP-1
        //                    var paramFyp2 = db.Fyp2EvaluationParameters
        //                        .Include("Fyp2SubParameter")
        //                        .FirstOrDefault(x => x.id == p.id && x.sessionID == sessionId);
        //                    if (paramFyp2 != null)
        //                    {
        //                        paramFyp2.name = p.name;
        //                        paramFyp2.percentage = p.percentage;
        //                        db.Fyp2SubParameter.RemoveRange(paramFyp2.Fyp2SubParameter);
        //                        if (p.subParameters != null)
        //                        {
        //                            foreach (var sub in p.subParameters)
        //                            {
        //                                db.Fyp2SubParameter.Add(new Fyp2SubParameter { parameterID = paramFyp2.id, name = sub.name, percentage = sub.percentage });
        //                            }
        //                        }
        //                    }
        //                }
        //            }
        //            db.SaveChanges();
        //            transaction.Commit();
        //            return Ok("Criteria updated successfully ✅");
        //        }
        //        catch (Exception ex)
        //        {
        //            transaction.Rollback();
        //            return InternalServerError(ex);
        //        }
        //    }
        //}



        //[HttpPost]
        //    [Route("save-criteria")]
        //    public IHttpActionResult SaveCriteria(SaveCriteriaDto model)
        //    {
        //        if (model == null || model.parameters == null || !model.parameters.Any())
        //            return BadRequest("Invalid criteria data");

        //        using (var transaction = db.Database.BeginTransaction())
        //        {
        //            try
        //            {
        //                foreach (var p in model.parameters)
        //                {
        //                    // MAIN PARAMETER
        //                    var param = new Fyp1EvaluationParameters
        //                    {
        //                        name = p.name,
        //                        percentage = p.percentage,
        //                        sessionID = model.sessionID,
        //                        allowEvaluation = p.allowEvaluation
        //                    };

        //                    db.Fyp1EvaluationParameters.Add(param);
        //                    db.SaveChanges(); // get param.id

        //                    // EVALUATORS
        //                    if (p.allowEvaluation && p.evaluators != null)
        //                    {
        //                        foreach (var evaluatorId in p.evaluators)
        //                        {
        //                            if (!db.Users.Any(u => u.id == evaluatorId))
        //                                return BadRequest($"Invalid evaluator ID: {evaluatorId}");

        //                            db.Fyp1ParameterEvaluator.Add(new Fyp1ParameterEvaluator
        //                            {
        //                                parameterID = param.id,
        //                                evaluatorID = evaluatorId
        //                            });
        //                        }
        //                    }

        //                    // SUB PARAMETERS
        //                    if (p.subParameters != null)
        //                    {
        //                        foreach (var sub in p.subParameters)
        //                        {
        //                            db.Fyp1SubParameter.Add(new Fyp1SubParameter
        //                            {
        //                                parameterID = param.id,
        //                                name = sub.name,
        //                                percentage = sub.percentage
        //                            });
        //                        }
        //                    }
        //                }

        //                db.SaveChanges();
        //                transaction.Commit();

        //                return Ok(new { message = "Criteria saved successfully" });
        //            }
        //            catch (Exception ex)
        //            {
        //                transaction.Rollback();
        //                return InternalServerError(ex);
        //            }
        //        }
        //    }


        [HttpPost]
        [Route("save-criteria")]
        public IHttpActionResult SaveCriteria(SaveCriteriaDto model)
        {
            if (model == null || model.parameters == null || !model.parameters.Any())
                return BadRequest("Invalid criteria data");
            // 🛡️ Validate Total
            var totalPercentage = model.parameters.Sum(p => p.percentage);
            if (totalPercentage != 100)
            {
                return BadRequest($"Total percentage must be 100%. Current: {totalPercentage}%");
            }
            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    foreach (var p in model.parameters)
                    {
                        // Main Parameter
                        var param = new Fyp1EvaluationParameters
                        {
                            name = p.name,
                            percentage = p.percentage,
                            sessionID = model.sessionID,
                            allowEvaluation = p.allowEvaluation
                        };
                        db.Fyp1EvaluationParameters.Add(param);
                        db.SaveChanges(); // get ID
                                          // Evaluators
                        if (p.allowEvaluation && p.evaluators != null)
                        {
                            foreach (var evId in p.evaluators)
                            {
                                db.Fyp1ParameterEvaluator.Add(new Fyp1ParameterEvaluator { parameterID = param.id, evaluatorID = evId });
                            }
                        }
                        // Sub Parameters
                        if (p.subParameters != null)
                        {
                            foreach (var sub in p.subParameters)
                            {
                                db.Fyp1SubParameter.Add(new Fyp1SubParameter { parameterID = param.id, name = sub.name, percentage = sub.percentage });
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


        [HttpGet]
        [Route("GetComitteeMembers")]
        public IHttpActionResult GetCommitteeMembers()
        {
            var members = db.Users
                .Where(u => u.role == "Committee")
                .Select(u => new
                {
                    id = u.id,
                    name = u.name
                }).ToList();

            return Ok(members);
        }



        [HttpGet]
        [Route("EligibleGroups/{regNum}")]
        public async Task<IHttpActionResult> GetEligibleGroups(string regNum)
        {
            try
            {
                // Get selected student
                var student = await db.Students
                    .Where(s => s.regNum == regNum)
                    .Select(s => new
                    {
                        s.regNum,
                        s.name,
                        TechnologyName = s.Technology.name
                    })
                    .FirstOrDefaultAsync();

                if (student == null)
                    return NotFound();

                var techName = student.TechnologyName;

                // Fetch groups where no member has same technology
                var groups = await db.ProjectGroups
                    .Where(g => !db.GroupMembers
                        .Where(m => m.groupID == g.id)
                        .Join(db.Students,
                            gm => gm.studentID,
                            st => st.regNum,
                            (gm, st) => st.Technology.name)
                        .Any(t => t == techName))
                    .Select(g => new
                    {
                        id = g.id,
                        members = db.GroupMembers
                            .Where(m => m.groupID == g.id)
                            .Join(db.Students,
                                gm => gm.studentID,
                                st => st.regNum,
                                (gm, st) => new
                                {
                                    name = st.name,
                                    technology = st.Technology.name
                                })
                            .ToList()
                    })
                    .ToListAsync();

                return Ok(groups);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("AddStudentToGroup")]
        public async Task<IHttpActionResult> AddStudentToGroup(int groupId , string regNum)
        {
     
                    db.GroupMembers.Add(new GroupMember
                    {

                        groupID = groupId,
                        studentID = regNum,
                        isAdmin = 0,

                    });



            await db.SaveChangesAsync();

            return Ok("Add Member To that Group Successfully!");
        }

        [HttpGet]
        [Route("all-students-with-group/{type}")]
        public async Task<IHttpActionResult> GetAllStudentsWithGroup(string type)
        {
            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name


            }).FirstOrDefault();
            var students = await db.Enrollments.Where(x=>x.sessionID ==list.id&& x.subject ==type)
                .Select(s => new
                {
                    regNum = s.studentID,
                    name = db.Students.Where(e=> e.regNum == s.studentID).Select(p=>p.name).FirstOrDefault(),
                   
                    technology = db.Students.Where(e => e.regNum == s.studentID).Select(p => p.Technology.name).FirstOrDefault(),
                    cgpa= db.Students.Where(e => e.regNum == s.studentID).Select(p => p.currentCGPA).FirstOrDefault(),

                    group = db.GroupMembers
                        .Where(g => g.studentID == s.studentID)
                        .Select(g => g.groupID)
                        .FirstOrDefault() ?? 0
                })
                .ToListAsync();

            return Ok(students);
        }
        private int CalculateStudentProgress_InMemory(int groupId, string studentId)
        {
            // All tasks for this group (individual + group tasks)
            var taskIds = db.Tasks
                .Where(t =>
                    t.groupID == groupId &&
                    (t.studentID == studentId || t.studentID == null)
                )
                .Select(t => t.id)
                .ToList();

            if (!taskIds.Any())
                return 0;

            // Evaluated scores
            var scores = db.TaskEvaluations
                .Where(e => taskIds.Contains((int)e.taskID) && e.score != null)
                .Select(e => e.score.Value)
                .ToList();

            if (!scores.Any())
                return 0;

            return (int)Math.Round(scores.Average());
        }



        [HttpGet]
        [Route("groups-details/{groupId}")]
        public IHttpActionResult GetApprovedGroupsDetail(int groupId)
        {
            try
            {
                // 🔹 STEP 1: SQL ONLY (no custom methods)
                var group = db.ProjectGroups
                    .Where(g => g.id == groupId)
                    .Select(g => new
                    {
                        groupName = g.id,
                        projectTitle = g.OfferedProject.Project.title,
                        supervisor = db.Users
                            .Where(u => u.id == g.supervisorID)
                            .Select(u => u.name)
                            .FirstOrDefault(),

                        members = g.GroupMembers
                            .Select(m => new
                            {
                                studentId = m.studentID,
                                studentName = m.Student.name,
                                Cgpa = m.Student.currentCGPA,
                                RegNum = m.Student.regNum,
                                Gender = m.Student.gender,
                                TechnologyId = m.Student.Technology.id,
                                TechnologyName = m.Student.Technology.name,
                                DepartmentName = m.Student.Department.name,
                                SessionName = m.Student.Session.name,
                                studentSection = m.Student.Section.name,
                                Email = m.Student.User.email
                            })
                            .ToList()
                    })
                    .FirstOrDefault();

                if (group == null)
                    return NotFound();

                // 🔹 STEP 2: IN-MEMORY PROGRESS CALCULATION
                var membersWithProgress = group.members
                    .Select(m => new
                    {
                        m.studentId,
                        m.studentName,
                        m.Cgpa,
                        m.RegNum,
                        m.Gender,
                        m.TechnologyId,
                        m.TechnologyName,
                        m.DepartmentName,
                        m.SessionName,
                        m.studentSection,
                        m.Email,
                        progress = CalculateStudentProgress_InMemory(groupId, m.studentId)
                    })
                    .ToList();

                // 🔹 FINAL RESPONSE
                return Ok(new
                {
                    group.groupName,
                    group.projectTitle,
                    group.supervisor,
                    members = membersWithProgress
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        [HttpGet]
        [Route("StudentByGroup/{groupId}")]
        public async Task<IHttpActionResult> GetStudentsByGroup(int groupId)
        {
            // 1️⃣ Get technologies already used in this group
            var groupTechnologies = await db.GroupMembers
                .Where(g => g.groupID == groupId)
                .Select(g => g.Student.Technology.name)
                .Distinct()
                .ToListAsync();

            // 2️⃣ Get latest session ID
            var latestSessionId = await db.Sessions
                .OrderByDescending(s => s.id)
                .Select(s => s.id)
                .FirstOrDefaultAsync();

            // 3️⃣ Fetch students
            var students = await db.Students
                .Where(s =>
                    !groupTechnologies.Contains(s.Technology.name) // 🚀 NOT same tech as group
                    && !db.GroupMembers.Any(g => g.studentID == s.regNum) // Not already in any group
                    && db.Enrollments.Any(e =>
                        e.studentID == s.regNum &&
                        e.sessionID == latestSessionId
                    )
                )
                .Select(s => new
                {
                    regNum = s.regNum,
                    name = s.name,
                    gender = s.gender,
                    currentCGPA = s.currentCGPA,

                    DepartmentId = s.Department.id,
                    DepartmentName = s.Department.name,

                    TechnologyId = s.Technology.id,
                    TechnologyName = s.Technology.name,

                    SessionId = s.Session.id,
                    SessionName = s.Session.name
                })
                .ToListAsync();

            return Ok(students);
        }

        [HttpGet]
        [Route("groups/approved/{activeFyp}")]
        public IHttpActionResult GetApprovedGroups(string activeFyp)
        {

            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new {

                e.id,
                e.name


            }).FirstOrDefault();

            var enrolledStudents = db.Enrollments.Where(x => x.subject == activeFyp &&x.sessionID == list.id).Select(s => new { studentID = s.studentID });

            var ids = enrolledStudents.Select(s => s.studentID).Distinct().ToList();

            var groups = db.ProjectGroups.Where(g => g.createdSession == list.id || ids.Contains(g.createdBy) || g.GroupMembers.Any(gm => ids.Contains(gm.studentID)))
                .Select(g => new
                {
                    groupName = g.id,
                    projectID = g.projectID,
                    projectTitle = g.projectID != null ? g.OfferedProject.Project.title : null,
                    supervisor = db.Users.Where(u => u.id == g.supervisorID).Select(s => s.name).FirstOrDefault(),
                    members = g.GroupMembers
                                .Select(m => m.Student.name + " (" + m.Student.regNum + ")")
                                .ToList()
                })
                .ToList();

            return Ok(groups);
        }

        [HttpGet]
        [Route("Profile")]
        public IHttpActionResult GetProfileData(string id)

        {
            var member = db.Users.Where(u => u.id == id).Select(s => new { s.id, s.name, s.password, s.email }).FirstOrDefault();
            if (member == null)
                return NotFound();
            return Ok(member);
        }

        [HttpPut]
        [Route("allocateSupervisor")]
        public IHttpActionResult supervisorAllocate(SupervisorAllocate model)
        {
            var group = db.ProjectGroups.Find(model.groupId);
            if (group == null)
                return NotFound();
            group.supervisorID = model.supervisorId;
            db.SaveChanges();
            return Ok("Supervisor Allocate Successfully!");
        }

        [HttpGet]
        [Route("group-count")]
        public IHttpActionResult GetSupervisorGroupCount()
        {

            var currentSession = db.Sessions.OrderByDescending(o => o.id).Select(e => new
            {

                e.id


            }).FirstOrDefault();

            var result =  db.Users
                .Where(u => u.role == "Supervisor")
                .GroupJoin(
                    db.ProjectGroups
                        .Where(pg => pg.createdSession == currentSession.id
                                     && pg.supervisorID != null),
                    supervisor => supervisor.id,
                    group => group.supervisorID,
                    (supervisor, groups) => new SupervisorGroupCountDto
                    {
                        SupervisorId = supervisor.id,
                        SupervisorName = supervisor.name,
                        TotalGroups = groups.Count()
                    }
                )
                .ToList();

            return Ok(result);
        }


        [HttpGet]
        [Route("today-meetings/{type}/{meetingId?}")]
        public IHttpActionResult GetTodayMeetings(string type, int? meetingId = null)
        {
            var today = DateTime.Today;
            var now = DateTime.Now;

            // 1. Auto-sync database (Isolated)
            var pendingQuery = db.GroupSchedules
                .Where(m => m.meetingDate == today && m.type == type && m.Status != "Completed");

            if (meetingId.HasValue)
                pendingQuery = pendingQuery.Where(m => m.comiteeMeetingID == meetingId.Value);

            var pending = pendingQuery.OrderBy(m => m.estimatedTime).ToList();

            bool isInProgress = pending.Any(g => g.Status == "In-Progress");
            bool isOverdue = pending.Any() && pending[0].Status == "Waiting" && pending[0].estimatedTime <= now.TimeOfDay;

            if (isInProgress || isOverdue)
            {
                ReindexQueue(type, meetingId);
            }

            // 2. Return results with strict sorting (Isolated for THIS meeting room)
            var resultQuery = db.GroupSchedules
                .Where(mq => mq.meetingDate == today && mq.type == type);

            if (meetingId.HasValue)
                resultQuery = resultQuery.Where(mq => mq.comiteeMeetingID == meetingId.Value);

            var result = resultQuery.ToList()
                .OrderBy(mq => mq.Status == "In-Progress" ? 0 : (mq.Status == "Waiting" ? 1 : 2))
                .ThenBy(mq => mq.estimatedTime)
                .Select(mq => new
                {
                    scheduleId = mq.id,
                    id = mq.comiteeMeetingID,
                    GroupIDs = mq.groupID,
                    MeetingTitle = mq.ComiteeMeeting.title,
                    MeetingDate = mq.meetingDate,
                    MeetingTime = mq.estimatedTime,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == mq.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    Status = mq.Status,
                    Type = mq.type
                })
                .ToList();

            return Ok(result);
        }

        [HttpGet]
        [Route("meetings")]
        public IHttpActionResult GetMeetings(string type, int groupId, string filter = "today", string studentId = null)
        {
            var today = DateTime.Today;

            var query = db.GroupSchedules
                .Where(m => m.type == type && m.groupID == groupId);

            if (!string.IsNullOrEmpty(studentId))
            {
                query = query.Where(m => m.studentID == null || m.studentID == studentId);
            }
            else
            {
                query = query.Where(m => m.studentID == null);
            }

            switch (filter.ToLower())
            {
                case "today":
                    query = query.Where(m => DbFunctions.TruncateTime(m.meetingDate) == today);
                    break;

                case "upcoming":
                    query = query.Where(m => m.meetingDate > today);
                    break;

                case "past":
                    query = query.Where(m => m.meetingDate < today);
                    break;
            }

            var result = query
                .OrderBy(m => m.meetingDate)
                .ThenBy(m => m.estimatedTime)
                .Select(m => new
                {
                    scheduleId = m.id,
                    location = m.ComiteeMeeting.venue,
                    meetingId = m.comiteeMeetingID,
                    groupId = m.groupID,
                    title = m.ComiteeMeeting.title,
                    date = m.meetingDate,
                    time = m.estimatedTime,
                    status = m.Status,
                    isGraded=m.ComiteeMeeting.isGraded,
                    isFileRequired=m.ComiteeMeeting.isFileRequired,
                    isUploaded=m.filePath,
                    type = m.type,
                    studentId = m.studentID,

                    description = m.ComiteeMeeting.meetingDescription
                })
                .Distinct().ToList();

            return Ok(result);
        }


        [HttpGet]
        [Route("getSpecificGroup/{groupId}")]
        public IHttpActionResult GetSpecificGroupDetails(int groupId)
        {
            var list = db.Sessions.OrderByDescending(o => o.id).Select(e => new
            {

                e.id,
                e.name


            }).FirstOrDefault();
            var memberList = db.GroupMembers.Where(gm => gm.groupID == groupId)
                .Select(gm => new
                {
                    GroupId=groupId,
                    gm.studentID,
                    studentName = gm.Student.name,
                    gm.Student.currentCGPA,
                    gm.Student.gender,
                    sessionID = list.id,

                    EnrollmentID = db.Enrollments
                        .Where(e => e.studentID == gm.studentID && e.sessionID == list.id)
                        .Select(e => e.id)
                        .FirstOrDefault(),

                    FinalTaskId = db.Fyp2Task.Where(t => t.groupId == groupId && t.sessionID == list.id && t.taskTitle == "Final Task").Select(t => t.id).FirstOrDefault(),
                    MidTaskId = db.Fyp2Task.Where(t => t.groupId == groupId && t.sessionID == list.id && t.taskTitle == "MidTask").Select(t => t.id).FirstOrDefault(),
                    TaskId = db.Fyp2Task.Where(t => t.groupId == groupId && t.sessionID == list.id).Select(t => t.id).FirstOrDefault(),

                    Tech =  db.Technologies.Where(t => t.id == gm.Student.selectedTech).Select(x => x.name).FirstOrDefault()

                }).ToList();




            return Ok(memberList);
        }

        [HttpGet, Route("getAllOfferedProjects")]
        public IHttpActionResult GetAlltOfferedProject()
        {
            var currentSession = db.Sessions.OrderByDescending(o => o.id).Select(e => new
            {

                e.id


            }).FirstOrDefault();

            var projects = db.OfferedProjects
                    .Where(op => op.sessionID == currentSession.id)
                    .Join(db.Projects,
                          op => op.projectID,
                          p => p.id,
                          (op, p) => new ProjectSessionDto
                          {
                              ProjectId = op.id,
                              Title = p.title,
                              SuggestedBy = p.suggestedBy,
                              Objectives = p.objectives

                          })
                    .ToList();
            return Ok(projects);
        }
        [HttpPut]
        [Route("allocateProject")]
        public IHttpActionResult projectAllocate(ProjectAllocate model)
        {
            var group = db.ProjectGroups.Find(model.groupId);
            if (group == null) 
                return NotFound();
            group.projectID = model.projectId;
            db.SaveChanges();
            return Ok("Project Allocate Successfully!");
        }

        [HttpGet]
        [Route("getAllSupervisors")]
        public IHttpActionResult getAllSupervisors()
        {

           var list =  db.Users.Where(u => u.role == "Supervisor")
                .Select(u => new
                {
                    u.id,
                    u.name
                }).ToList();

            return Ok(list);
        }

        [HttpGet]
        [Route("IsProjectAllocate/{groupId}")]
        public IHttpActionResult IsProjectAllocate(int groupId)
        {

            bool check = db.ProjectGroups.Any(g => g.id == groupId && g.projectID != null);

            return Ok(check);
        }

        [HttpGet]
        [Route("IsSupervisorAllocate/{groupId}")]
        public IHttpActionResult IsSupervisorAllocate(int groupId)
        {

            bool check = db.ProjectGroups.Any(g => g.id == groupId && g.supervisorID != null);

            return Ok(check);
        }


        [HttpGet]
        [Route("EnrolledStudents/{type}")]
        public IHttpActionResult GetEnrolledStudent(string type)
        {



            var enrolledStudents = db.Enrollments.Where(x => x.subject == type).Select(s => new { studentID = s.studentID });

            var ids = enrolledStudents.Select(s => s.studentID).Distinct().ToList();
            var result = db.ProjectGroups
        .Where(gm => ids.Contains(gm.createdBy))
        .Select(gm => new
        {
            StudentID = gm.createdBy,
            GroupID = gm.id
        })
        .ToList();

            return Ok(result);
        }

        [HttpPost]
        [Route("update-meeting-times-dynamic")]
        public IHttpActionResult UpdateMeetingTimesDynamic()
        {
            var now = DateTime.Now;
            var today = DateTime.Today;

            // Get all today's meetings that are not completed
            var meetings = db.GroupSchedules
                .Where(m => m.meetingDate == today && m.Status != "Completed")
                .OrderBy(m => m.estimatedTime)
                .ToList();

            if (!meetings.Any())
                return Ok(new { message = "No pending meetings to update." });

            // Only update if the first group is WAITING and overdue
            // This self-heals the queue if meetings haven't started on time
            // Auto-update using 'Live Sliding' logic
            bool isInProgress = meetings.Any(g => g.Status == "In-Progress");
            bool isOverdue = meetings.Any() && meetings[0].Status == "Waiting" && meetings[0].estimatedTime <= now.TimeOfDay;

            if (isInProgress || isOverdue)
            {
                ReindexQueue(meetings[0].type);
                return Ok(new { message = "Live Sliding sync applied" });
            }

            return Ok(new { message = "Queue is on track." });
        }
        [HttpPost]
        [Route("handle-delay")]
        public IHttpActionResult HandleDelay(DelayHandlerDto model)
        {
            try
            {
                if (model == null)
                    return BadRequest("Invalid data");

                var remainingGroups = db.GroupSchedules
                    .Where(g => g.comiteeMeetingID == model.MeetingId &&
                                g.Status != "Completed" &&
                                g.meetingDate == DateTime.Today)
                    .OrderBy(g => g.estimatedTime)
                    .ToList();

                if (!remainingGroups.Any())
                    return Ok("No remaining groups");

                // OPTION 1 → ADJUST INTO NEXT MEETING
                if (model.Action == "merge")
                {
                    var nextMeeting = db.ComiteeMeetings
                        .Where(m => m.startDate > DateTime.Today)
                        .OrderBy(m => m.startDate)
                        .FirstOrDefault();

                    if (nextMeeting == null)
                        return BadRequest("No upcoming meeting found");

                    foreach (var group in remainingGroups)
                    {
                        group.comiteeMeetingID = nextMeeting.id;
                        group.meetingDate = nextMeeting.startDate;
                        group.estimatedTime = nextMeeting.startTime;
                    }

                    db.SaveChanges();

                    // Notify of Merge
                    NotifyRelevantGroups(nextMeeting.id, remainingGroups[0].type, "Meeting Rescheduled", $"Your evaluation has been merged into meeting: {nextMeeting.title}");

                    return Ok("Remaining groups merged into next meeting");
                }

                // OPTION 2 → CREATE NEW MEETING
                else if (model.Action == "new")
                {
                    var newMeeting = new ComiteeMeeting
                    {
                        title = "Rescheduled Meeting",
                        meetingDescription = "Auto-created due to delay",
                        startDate = model.NewDate,
                        endDate = model.NewDate,
                        startTime = model.NewStartTime,
                        endTime = model.NewEndTime,
                        venue = model.Venue,
                        sessionID = model.SessionID
                    };

                    db.ComiteeMeetings.Add(newMeeting);
                    db.SaveChanges();

                    // CALCULATE DYNAMIC AVERAGE DURATION
                    // Use type from first group
                    string fypType = remainingGroups[0].type;
                    var completed = db.GroupSchedules
                        .Where(g => g.type == fypType && g.meetingDate == DateTime.Today && g.Status == "Completed" && g.isAttend > 1)
                        .ToList();

                    int averageDuration = 20;
                    if (completed.Any()) averageDuration = (int)completed.Average(g => g.isAttend ?? 20);

                    TimeSpan time = model.NewStartTime;

                    foreach (var group in remainingGroups)
                    {
                        group.comiteeMeetingID = newMeeting.id;
                        group.meetingDate = model.NewDate;
                        group.estimatedTime = time;

                        time = time.Add(TimeSpan.FromMinutes(averageDuration));
                    }

                    db.SaveChanges();

                    // Notify of New Rescheduled Meeting
                    NotifyRelevantGroups(newMeeting.id, fypType, "Meeting Rescheduled", $"A new evaluation session has been created for you: {newMeeting.title} on {newMeeting.startDate:dd MMM yyyy}");

                    return Ok("New meeting created and groups reassigned");
                }

                return BadRequest("Invalid action");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        public class DelayHandlerDto
{
    public int MeetingId { get; set; }
    public string Action { get; set; } // "merge" OR "new"

    // For new meeting
    public DateTime NewDate { get; set; }
    public TimeSpan NewStartTime { get; set; }
    public TimeSpan NewEndTime { get; set; }
    public string Venue { get; set; }
    public int SessionID { get; set; }
}

        [HttpPost]
        [Route("update-group-attendance")]
        public IHttpActionResult UpdateGroupAttendance(UpdateGroupAttendanceDto model)
        {
            var schedule = db.GroupSchedules
                .FirstOrDefault(x =>
                    x.groupID == model.GroupId &&
                    x.comiteeMeetingID == model.MeetingId);

            if (schedule == null)
                return BadRequest("Meeting Schedule Not Found");

            if (model.IsAttended)
            {
                schedule.isAttend = 1;
                schedule.Status = "In-Progress";
                schedule.estimatedTime = DateTime.Now.TimeOfDay; // Mark as LIVE NOW
            }
            else
            {
                schedule.isAttend = 0;
                schedule.Status = "Waiting";
            }
            
            db.SaveChanges();

            // ✅ ATOMIC RE-INDEX (Isolated for THIS meeting room)
            if (model.IsAttended)
            {
                ReindexQueue(schedule.type, model.MeetingId);
            }

            return Ok("Attendance Updated Successfully");
        }

        [HttpPost]
        [Route("update-group-status")]
        public IHttpActionResult UpdateGroupStatus(UpdateGroupStatusDto model)
        {
            var schedule = db.GroupSchedules
                .FirstOrDefault(x =>
                    x.groupID == model.GroupId &&
                    x.comiteeMeetingID == model.MeetingId);

            if (schedule == null)
                return BadRequest("Meeting Schedule Not Found");

            var now = DateTime.Now;
            var today = DateTime.Today;

            // ✅ CALCULATE ACTUAL DURATION AND STORE IN isAttend
            if (model.Status == "Completed")
            {
                if (schedule.estimatedTime.HasValue)
                {
                    var duration = (int)(now.TimeOfDay - schedule.estimatedTime.Value).TotalMinutes;
                    if (duration <= 0) duration = 15; // Minimum 15 min safety
                    schedule.isAttend = duration; // Repurpose isAttend to store actual minutes taken
                }
                schedule.Status = "Completed";
            }
            else
            {
                schedule.Status = model.Status;
            }

            db.SaveChanges();

            // ✅ ATOMIC RE-INDEX (Isolated for THIS meeting room)
            if (model.Status == "Completed")
            {
                ReindexQueue(schedule.type, model.MeetingId);
            }

            return Ok("Status Updated Successfully");
        }

        [HttpPost]
        [Route("update-student-attendance")]
        public IHttpActionResult UpdateStudentAttendance(UpdateStudentAttendanceDto model)
        {
            var schedule = db.MeetingAttendances
                .FirstOrDefault(x =>
                    x.scheduleID == model.scheduleId &&
                    x.studentID == model.studentId);

            if (schedule == null)
                return BadRequest("Meeting Schedule Not Found");
            if (model.isAttended)
                 schedule.attendance =true;
            else schedule.attendance = false;
            db.SaveChanges();

            return Ok("Attendance Updated Successfully");
        }


        [HttpGet]
        [Route("get-group-attendance")]
        public IHttpActionResult GetGroupAttendance(int groupId,int meetingId)
        {
            var schedule = db.GroupSchedules
                .FirstOrDefault(x =>
                    x.groupID == groupId &&
                    x.comiteeMeetingID == meetingId);

            if (schedule == null)
                return BadRequest("Meeting Schedule Not Found");
            if (schedule.isAttend == 1)
                return Ok(new {
                    scheduleId= schedule.id,
                    IsAttend= true

                });
            else
                return Ok(new
                {
                    scheduleId = schedule.id,
                    IsAttend = false
                });   

        }
        [HttpGet]
        [Route("get-student-attendance")]
        public IHttpActionResult GetStudentAttendance(int scheduleId, string studentId)
        {
            var schedule = db.MeetingAttendances
                 .FirstOrDefault(x =>
                     x.scheduleID == scheduleId &&
                     x.studentID == studentId);

            if (schedule == null)
                return BadRequest("Meeting Schedule Not Found");
            if (schedule.attendance==true)
                return Ok(new
                {
                    scheduleId = schedule.scheduleID,
                    IsAttend = true

                });
            else
                return Ok(new
                {
                    scheduleId = schedule.scheduleID,
                    IsAttend = false
                });

        }


        [HttpPost]
        [Route("update-meeting-times")]
        public IHttpActionResult UpdateMeetingTimes([FromBody] List<MeetingTimeUpdateModel> updatedMeetings)
        {
            if (updatedMeetings == null || !updatedMeetings.Any())
                return BadRequest("No meetings provided");

            foreach (var updatedMeeting in updatedMeetings)
            {
                var meeting = db.GroupSchedules.FirstOrDefault(m => m.comiteeMeetingID == updatedMeeting.ComiteeMeetingID && m.groupID == updatedMeeting.GroupID);
                if (meeting != null)
                {
                    meeting.estimatedTime = updatedMeeting.EstimatedTime;
                }
            }

            db.SaveChanges();

            return Ok(new { message = "Meeting times updated in DB." });
        }

        [HttpGet]
        [Route("today-meetings-priority/{meetingId}")]
        public IHttpActionResult GetTodayMeetingsWithPriority(int meetingId)
        {
            var today = DateTime.Today;
            var now = DateTime.Now;

            // 1️⃣ Fetch & Order by priority criteria for THIS specific meeting
            var meetingInfo = db.GroupSchedules.Find(meetingId);
            if (meetingInfo == null) return NotFound();
            string type = meetingInfo.type; // Extract phase from meeting

            var meetings = db.GroupSchedules
                .Where(mq => mq.meetingDate == today && mq.comiteeMeetingID == meetingId && mq.Status != "Completed")
                .Select(mq => new
                {
                    mq.id,
                    mq.groupID,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == mq.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    HasFemale = db.GroupMembers.Any(g =>
                        g.groupID == mq.groupID &&
                        g.Student.gender == "F"
                    )
                })
                .ToList()
                .OrderByDescending(x => x.HasFemale)
                .ThenBy(x => x.SupervisorName)
                .ToList();

            // 2️⃣ Apply Atomic Re-index (Isolated)
            DateTime sequenceTime = now;
            foreach (var item in meetings)
            {
                var schedule = db.GroupSchedules.Find(item.id);
                if (schedule != null)
                {
                    schedule.estimatedTime = sequenceTime.TimeOfDay; 
                    sequenceTime = sequenceTime.AddMinutes(1);
                }
            }
            db.SaveChanges();

            // 3️⃣ Re-index to apply the actual dynamic timeline (e.g. In 20 min, In 40 min...)
            ReindexQueue(type, meetingId);

            // 4️⃣ Return Updated Data (Strict Sorting)
            var updatedResult = db.GroupSchedules
                .Where(mq => mq.meetingDate == today && mq.comiteeMeetingID == meetingId)
                .ToList()
                .OrderBy(mq => mq.Status == "In-Progress" ? 0 : (mq.Status == "Waiting" ? 1 : 2))
                .ThenBy(mq => mq.estimatedTime)
                .Select(mq => new
                {
                    scheduleId = mq.id,
                    id = mq.comiteeMeetingID,
                    GroupIDs = mq.groupID,
                    MeetingTitle = mq.ComiteeMeeting.title,
                    MeetingDate = mq.meetingDate,
                    MeetingTime = mq.estimatedTime,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == mq.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    HasFemale = db.GroupMembers.Any(g => g.groupID == mq.groupID && g.Student.gender == "F"),
                    Status = mq.Status,
                    Type = mq.type
                })
                .ToList();

            return Ok(updatedResult);
        }

        [HttpPost]
        [Route("reschedule-meeting")]
        public IHttpActionResult RescheduleMeeting(RescheduleMeetingDto model)
        {
            try
            {
                var existingSchedule = db.GroupSchedules.FirstOrDefault(gs => gs.comiteeMeetingID == model.MeetingId && gs.groupID == model.GroupId && gs.studentID == null);
                if (existingSchedule == null) return BadRequest("Meeting schedule not found.");

                TimeSpan newTimeSpan;
                if (!TimeSpan.TryParse(model.NewTime, out newTimeSpan))
                {
                    return BadRequest("Invalid time format.");
                }

                string meetingTitle = existingSchedule.ComiteeMeeting?.title ?? "Committee Meeting";

                if (string.IsNullOrEmpty(model.StudentId) || model.StudentId == "All")
                {
                    // Reschedule for whole group
                    existingSchedule.meetingDate = model.NewDate;
                    existingSchedule.estimatedTime = newTimeSpan;
                    existingSchedule.Status = "Scheduled";
                    db.SaveChanges();
                    
                    ReindexQueue(existingSchedule.type, model.MeetingId);
                    
                    NotifyReschedule(model.MeetingId, existingSchedule.type, $"Meeting Rescheduled: {meetingTitle}", $"Your committee meeting for Group {model.GroupId} has been rescheduled to {model.NewDate.ToString("yyyy-MM-dd")} at {model.NewTime}.", model.GroupId, null);
                }
                else
                {
                    // Reschedule for ONE student. Create a clone GroupSchedule for that student.
                    var newSchedule = new GroupSchedule
                    {
                        groupID = model.GroupId,
                        comiteeMeetingID = model.MeetingId,
                        meetingDate = model.NewDate,
                        estimatedTime = newTimeSpan,
                        Status = "Scheduled",
                        type = existingSchedule.type,
                        studentID = model.StudentId,
                        isAttend = 0
                    };
                    db.GroupSchedules.Add(newSchedule);
                    db.SaveChanges();
                    
                    ReindexQueue(newSchedule.type, model.MeetingId);
                    
                    NotifyReschedule(model.MeetingId, newSchedule.type, $"Meeting Rescheduled (Individual): {meetingTitle}", $"Your individual committee meeting has been rescheduled to {model.NewDate.ToString("yyyy-MM-dd")} at {model.NewTime}.", model.GroupId, model.StudentId);
                }

                return Ok("Meeting Rescheduled Successfully");
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        private void NotifyReschedule(int meetingId, string fypType, string title, string message, int groupId, string studentId)
        {
            try
            {
                var notification = new Notification
                {
                    Title = title,
                    Message = message,
                    Type = "CommitteeMeeting",
                    ReferenceID = meetingId,
                    CreatedAt = DateTime.Now,
                    SenderID = null,
                    SenderRole = "Committee"
                };
                db.Notifications.Add(notification);
                db.SaveChanges();

                var supervisorId = db.ProjectGroups.Where(p => p.id == groupId).Select(s => s.supervisorID).FirstOrDefault();
                if (!string.IsNullOrEmpty(supervisorId))
                {
                    db.NotificationRecipients.Add(new NotificationRecipient {
                        NotificationID = notification.NotificationID,
                        RecipientID = supervisorId,
                        RecipientRole = "Supervisor",
                        IsRead = 0
                    });
                }

                if (string.IsNullOrEmpty(studentId) || studentId == "All")
                {
                    var members = db.GroupMembers.Where(gm => gm.groupID == groupId).Select(gm => gm.studentID).ToList();
                    foreach (var sid in members)
                    {
                        db.NotificationRecipients.Add(new NotificationRecipient {
                            NotificationID = notification.NotificationID,
                            RecipientID = sid,
                            RecipientRole = "Student",
                            IsRead = 0
                        });
                    }
                }
                else
                {
                    db.NotificationRecipients.Add(new NotificationRecipient {
                        NotificationID = notification.NotificationID,
                        RecipientID = studentId,
                        RecipientRole = "Student",
                        IsRead = 0
                    });
                }
                
                db.SaveChanges();
            }
            catch { /* silent */ }
        }

        [HttpGet]
        [Route("today-meetings-supervisor-priority/{meetingId}")]
        public IHttpActionResult GetTodayMeetingsWithSupervisorPriority(int meetingId)
        {
            var today = DateTime.Today;
            var now = DateTime.Now;

            var meetingInfo = db.GroupSchedules.Find(meetingId);
            if (meetingInfo == null) return NotFound();
            string type = meetingInfo.type;

            // 1️⃣ Fetch & Order by Supervisor Name (A-Z) for THIS meeting
            var meetings = db.GroupSchedules
                .Where(mq => mq.meetingDate == today && mq.comiteeMeetingID == meetingId && mq.Status != "Completed")
                .Select(mq => new
                {
                    mq.id,
                    mq.groupID,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == mq.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    mq.estimatedTime
                })
                .ToList()
                .OrderBy(x => x.SupervisorName)
                .ToList();

            // 2️⃣ Apply Atomic Re-index (Isolated)
            DateTime sequenceTime = now;
            foreach (var item in meetings)
            {
                var schedule = db.GroupSchedules.Find(item.id);
                if (schedule != null)
                {
                    schedule.estimatedTime = sequenceTime.TimeOfDay; 
                    sequenceTime = sequenceTime.AddMinutes(1);
                }
            }
            db.SaveChanges();

            ReindexQueue(type, meetingId);

            // 3️⃣ Return Updated Data
            var updatedResult = db.GroupSchedules
                .Where(mq => mq.meetingDate == today && mq.type == type)
                .Select(mq => new
                {
                    scheduleId = mq.id,
                    id = mq.comiteeMeetingID,
                    GroupIDs = mq.groupID,
                    MeetingTitle = mq.ComiteeMeeting.title,
                    MeetingDate = mq.meetingDate,
                    MeetingTime = mq.estimatedTime,
                    SupervisorName = db.ProjectGroups.Where(pg => pg.id == mq.groupID)
                                        .Join(db.Users, pg => pg.supervisorID, u => u.id, (pg, u) => u.name)
                                        .FirstOrDefault(),
                    Status = mq.Status,
                    Type = mq.type
                })
                .ToList()
                .OrderBy(m => m.Status == "In-Progress" ? 0 : (m.Status == "Waiting" ? 1 : 2))
                .ThenBy(m => m.MeetingTime)
                .ToList();

            return Ok(updatedResult);
        }
        [HttpPost]
        [Route("update-queue-order")]
        public IHttpActionResult UpdateQueueOrder(List<int> scheduleIds)
        {
            if (scheduleIds == null || !scheduleIds.Any())
                return BadRequest("No schedule IDs provided.");

            var today = DateTime.Today;
            var now = DateTime.Now;

            // 1. Establish the sequence in the database (Sequence Lock)
            DateTime sequenceTime = now;
            foreach (var id in scheduleIds)
            {
                var schedule = db.GroupSchedules.Find(id);
                if (schedule != null && schedule.meetingDate == today)
                {
                    // Give them 1-minute increments to lock the relative order
                    schedule.estimatedTime = sequenceTime.TimeOfDay;
                    sequenceTime = sequenceTime.AddMinutes(1);
                }
            }
            db.SaveChanges();

            // 2. Trigger the Atomic Re-index (Isolated for THIS meeting room)
            var firstGroup = db.GroupSchedules.Find(scheduleIds[0]);
            if (firstGroup != null)
            {
                NotifyRelevantGroups(firstGroup.comiteeMeetingID ?? 0, firstGroup.type, "Queue Reordered", "The evaluation sequence has been updated by the committee.");
                ReindexQueue(firstGroup.type, firstGroup.comiteeMeetingID);
            }

            return Ok(new { message = "Queue order synchronized globally" });
        }

        [HttpGet]
        [Route("IsAnyFemale/{groupId}")]
        public IHttpActionResult IsAnyFemale(int groupId) {

            var check = db.GroupMembers.Where(g => g.groupID ==groupId && g.Student.gender=="F").Select(s => s.studentID ).FirstOrDefault();
            if (check!=null)
                return Ok(true);
            return Ok(false);
        }

        [HttpGet]
        [Route("get-meeting-data/{meetingId}")]
        public IHttpActionResult GetMeetingData(int meetingId)
        {
            var meeting = db.ComiteeMeetings.Find(meetingId);
            
            if (meeting == null)
                return NotFound();

            var groups = db.ProjectGroups
                .Where(g => g.createdSession == meeting.sessionID && g.isFinalized == 1)
                .Select(g => new
                {
                    g.id,
                   
                    SupervisorName = g.supervisorID != null
                        ? db.Users.Where(u => u.id == g.supervisorID)
                                  .Select(u => u.name)
                                  .FirstOrDefault()
                        : null
                })
                .ToList();

            if (!groups.Any())
                return BadRequest("No groups found");

            // Sort groups
            var orderedGroups = groups
                .OrderBy(g => g.SupervisorName == null) // supervisors first
                .ThenBy(g => g.SupervisorName)
                .ToList();

            var totalMinutes =
                (meeting.endTime.Value - meeting.startTime.Value).TotalMinutes;

            var minutesPerGroup = totalMinutes / orderedGroups.Count;

            return Ok(new
            {
                meetingId = meeting.id,
                meetingStartTime = meeting.startTime,
                meetingEndTime = meeting.endTime,
                totalGroups = orderedGroups.Count,
                minutesPerGroup = minutesPerGroup,
                groups = orderedGroups
            });
        }

        [HttpGet]
        [Route("meeting-distribution-preview")]
        public IHttpActionResult GetMeetingDistributionPreview(string type, int sessionId, DateTime startDate, DateTime endDate, string[] selectedDays)
        {
            try
            {
                // ================= VALIDATION =================
                if (string.IsNullOrWhiteSpace(type))
                    return BadRequest("Type is required");

                if (selectedDays == null || !selectedDays.Any())
                    return BadRequest("Select at least one day");

                if (startDate > endDate)
                    return BadRequest("Invalid date range");

                // ================= DAY MAPPING =================
                var dayMap = new Dictionary<string, DayOfWeek>
        {
            { "Mon", DayOfWeek.Monday },
            { "Tue", DayOfWeek.Tuesday },
            { "Wed", DayOfWeek.Wednesday },
            { "Thu", DayOfWeek.Thursday },
            { "Fri", DayOfWeek.Friday },
            { "Sat", DayOfWeek.Saturday },
            { "Sun", DayOfWeek.Sunday }
        };

                var selectedDayEnums = selectedDays
                    .Where(d => dayMap.ContainsKey(d))
                    .Select(d => dayMap[d])
                    .ToList();

                // ================= VALID DATES =================
                var validDates = new List<DateTime>();
                DateTime temp = startDate;

                while (temp <= endDate)
                {
                    if (selectedDayEnums.Contains(temp.DayOfWeek))
                        validDates.Add(temp);

                    temp = temp.AddDays(1);
                }

                int totalDays = validDates.Count;

                if (totalDays == 0)
                {
                    return Ok(new
                    {
                        totalGroups = 0,
                        totalDays = 0,
                        groupsPerDay = 0
                    });
                }

                // ================= GET GROUPS FROM DB =================
                var enrolledStudents = db.Enrollments
                    .Where(e => e.subject == type && e.sessionID == sessionId)
                    .Select(e => e.studentID)
                    .Distinct()
                    .ToList();

                var totalGroups = db.ProjectGroups
                    .Where(g => enrolledStudents.Contains(g.createdBy))
                    .Select(g => g.id)
                    .Distinct()
                    .Count();

                // ================= DISTRIBUTION =================
                int groupsPerDay = totalGroups / totalDays;
                int extraGroups = totalGroups % totalDays;

                // ================= RESPONSE =================
                return Ok(new
                {
                    totalGroups = totalGroups,
                    totalDays = totalDays,
                    groupsPerDay = groupsPerDay,
                    extraGroups = extraGroups
                });
            }
            catch (Exception)
            {
                return InternalServerError(new Exception("Error calculating preview"));
            }
        }

        [HttpGet]
        [Route("my-meetings/{userId}/{fypType}")]
        public IHttpActionResult GetMyCreatedMeetings(string userId, string fypType)
        {
            var today = DateTime.Today;

            // 1. Get the meetings for this phase
            // Since the DB doesn't have a 'createdBy' field in ComiteeMeeting yet,
            // we return all meetings for this phase, but we include a flag if the user is an evaluator
            var meetings = db.GroupSchedules
                .Where(gs => gs.type == fypType)
                .GroupBy(gs => gs.comiteeMeetingID)
                .Select(g => new
                {
                    MeetingId = g.Key,
                    MeetingTitle = g.FirstOrDefault().ComiteeMeeting.title,
                    Description = g.FirstOrDefault().ComiteeMeeting.meetingDescription,
                    Date = g.FirstOrDefault().ComiteeMeeting.startDate,
                    Venue = g.FirstOrDefault().ComiteeMeeting.venue,
                    GroupCount = g.Count(),
                    Status = g.FirstOrDefault().ComiteeMeeting.startDate > today ? "Incoming" : 
                             (g.FirstOrDefault().ComiteeMeeting.startDate < today ? "Past" : "Ongoing")
                })
                .OrderByDescending(m => m.Date)
                .ToList();

            return Ok(meetings);
        }

        [HttpGet]
        [Route("meeting-groups/{meetingId}")]
        public IHttpActionResult GetGroupsByMeeting(int meetingId)
        {
            var groups = db.GroupSchedules
                .Where(gs => gs.comiteeMeetingID == meetingId)
                .Select(gs => new
                {
                    gs.id,
                    gs.groupID,
                    GroupName = "Group "+gs.id, // Assuming 'name' is the group name or leader name
                    Supervisor = db.Users.Where( u => u.id == db.ProjectGroups.Where( p => p.id == gs.groupID).Select(s => s.supervisorID).FirstOrDefault()).Select(n => n.name),
                    Status = gs.Status,
                    Members = db.GroupMembers
                        .Where(gm => gm.groupID == gs.groupID)
                        .Select(gm => new {
                            gm.studentID,
                            Name = gm.Student.name
                        }).ToList()
                })
                .ToList();

            return Ok(groups);
        }

        [HttpPost]
        [Route("schedule-meeting")]
        public IHttpActionResult ScheduleMeeting(ScheduleCommitteeMeetingDto model, string type, string userId)
        {
            try
            {
                // ================= VALIDATION =================
                if (model == null)
                    return BadRequest("Meeting data is missing");

                if (string.IsNullOrWhiteSpace(type))
                    return BadRequest("Project type is required");

                if (!ModelState.IsValid)
                    return BadRequest("Invalid meeting data");

                if (model.startDate > model.endDate)
                    return BadRequest("Start date cannot be after end date");

                if (model.startTime >= model.endTime)
                    return BadRequest("Start time must be before end time");

                // ================= CREATE MEETING =================
                var meeting = new ComiteeMeeting
                {
                    title = model.title,
                    meetingDescription = model.meetingDescription,
                    startDate = model.startDate,
                    endDate = model.endDate,
                    startTime = model.startTime,
                    endTime = model.endTime,
                    venue = model.venue,
                    selectedDays = string.Join(",", model.selectedDays),
                    sessionID = model.sessionID,
                    isGraded = model.isGraded,
                    isFileRequired = model.isFileRequired
                };

                db.ComiteeMeetings.Add(meeting);
                db.SaveChanges(); // ✅ IMPORTANT (get meeting.id)

                // ================= FETCH ENROLLED STUDENTS =================
                var enrolledStudents = db.Enrollments
                    .Where(e => e.subject == type && e.sessionID == model.sessionID)
                    .Select(e => e.studentID)
                    .Distinct()
                    .ToList();

                if (!enrolledStudents.Any())
                {
                    return Ok(new
                    {
                        message = "Meeting created but no enrolled students found",
                        meetingId = meeting.id
                    });
                }

                // ================= FETCH GROUPS =================
                var groups = (
                    from g in db.ProjectGroups
                    join u in db.Users on g.supervisorID equals u.id into sup
                    from supervisor in sup.DefaultIfEmpty()
                    where enrolledStudents.Contains(g.createdBy)
                    select new GroupScheduleVM
                    {
                        GroupID = g.id,
                        SupervisorID = g.supervisorID,
                        SupervisorName = supervisor != null ? supervisor.name : null
                    }
                ).ToList();

                if (!groups.Any())
                {
                    return Ok(new
                    {
                        message = "Meeting created but no project groups found",
                        meetingId = meeting.id
                    });
                }

                // ================= ORDERING =================
                List<GroupScheduleVM> orderedGroups;

                if (type == "FYP-1")
                {
                    var withSupervisor = groups
                        .Where(g => g.SupervisorID != null)
                        .OrderBy(g => g.SupervisorName)
                        .ToList();

                    var withoutSupervisor = groups
                        .Where(g => g.SupervisorID == null)
                        .OrderBy(g => g.GroupID)
                        .ToList();

                    orderedGroups = withSupervisor.Concat(withoutSupervisor).ToList();
                }
                else if (type == "FYP-2")
                {
                    orderedGroups = groups
                        .OrderBy(g => g.SupervisorName)
                        .ThenBy(g => g.GroupID)
                        .ToList();
                }
                else
                {
                    return BadRequest("Invalid project type");
                }

                // ================= VALID MEETING DAYS =================
                var dayMap = new Dictionary<string, DayOfWeek>
{
    { "Mon", DayOfWeek.Monday },
    { "Tue", DayOfWeek.Tuesday },
    { "Wed", DayOfWeek.Wednesday },
    { "Thu", DayOfWeek.Thursday },
    { "Fri", DayOfWeek.Friday },
    { "Sat", DayOfWeek.Saturday },
    { "Sun", DayOfWeek.Sunday }
};

                var selectedDayEnums = model.selectedDays
                    .Where(d => dayMap.ContainsKey(d))
                    .Select(d => dayMap[d])
                    .ToList();
                var validDates = new List<DateTime>();
                DateTime tempDate = model.startDate;

                while (tempDate <= model.endDate)
                {
                    if (selectedDayEnums.Contains(tempDate.DayOfWeek))
                        validDates.Add(tempDate);

                    tempDate = tempDate.AddDays(1);
                }

                if (!validDates.Any())
                    return BadRequest("No valid meeting days found");

                // ================= DISTRIBUTION =================
                int totalGroups = orderedGroups.Count;
                int totalDays = validDates.Count;

                int groupsPerDay = totalGroups / totalDays;
                int extraGroups = totalGroups % totalDays;

                int totalMinutesPerDay =
                    (int)(model.endTime - model.startTime).TotalMinutes;

                int minutesPerGroup = totalMinutesPerDay / (groupsPerDay == 0 ? 1 : groupsPerDay);

                if (minutesPerGroup <= 0)
                    minutesPerGroup = 15;

                // ================= CREATE SCHEDULE =================
                int groupIndex = 0;

                foreach (var date in validDates)
                {
                    TimeSpan currentTime = model.startTime;

                    int todaysGroups = groupsPerDay;

                    if (extraGroups > 0)
                    {
                        todaysGroups++;
                        extraGroups--;
                    }

                    for (int i = 0; i < todaysGroups; i++)
                    {
                        if (groupIndex >= orderedGroups.Count)
                            break;

                        var group = orderedGroups[groupIndex];

                        db.GroupSchedules.Add(new GroupSchedule
                        {
                            groupID = group.GroupID,
                            comiteeMeetingID = meeting.id,
                            estimatedTime = currentTime,
                            meetingDate = date,
                            Status = "Waiting",
                            filePath = null,
                            isAttend = 0,
                            type = type
                        });

                        currentTime = currentTime.Add(TimeSpan.FromMinutes(minutesPerGroup));
                        groupIndex++;
                    }
                }

                db.SaveChanges();

                // ================= 🔔 NOTIFICATIONS =================
                var groupIds = orderedGroups.Select(g => g.GroupID).ToList();

                var students = db.GroupMembers
                    .Where(gm => groupIds.Contains((int)gm.groupID))
                    .Select(gm => gm.studentID)
                    .Distinct()
                    .ToList();

                // ================= BROADCAST NOTIFICATIONS =================
                NotifyRelevantGroups(meeting.id, type, "New Committee Meeting Scheduled", $"Meeting scheduled from {meeting.startDate:dd MMM yyyy} to {meeting.endDate:dd MMM yyyy} at {meeting.venue}", userId);

                // ================= RESPONSE =================
                return Ok(new
                {
                    message = "Meeting created and schedule generated successfully",
                    meetingId = meeting.id,
                    totalGroups = totalGroups,
                    totalDays = totalDays,
                    groupsPerDay = groupsPerDay
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPut]
        [Route("{meetingId}")]
        public IHttpActionResult UpdateMeeting(int meetingId, [FromBody] ScheduleCommitteeMeetingDto model, [FromUri] string type, [FromUri] string userId)
        {
            try
            {
                if (model == null)
                    return BadRequest("Meeting data is missing");

                var meeting = db.ComiteeMeetings.Find(meetingId);
                if (meeting == null)
                    return NotFound();

                meeting.title = model.title;
                meeting.meetingDescription = model.meetingDescription;
                meeting.venue = model.venue;
                meeting.startTime = model.startTime;
                meeting.endTime = model.endTime;
                meeting.isGraded = model.isGraded;
                meeting.isFileRequired = model.isFileRequired;

                bool datesChanged = meeting.startDate != model.startDate ||
                                    meeting.endDate != model.endDate ||
                                    meeting.selectedDays != string.Join(",", model.selectedDays);

                if (datesChanged)
                {
                    meeting.startDate = model.startDate;
                    meeting.endDate = model.endDate;
                    meeting.selectedDays = string.Join(",", model.selectedDays);

                    var existingSchedules = db.GroupSchedules.Where(gs => gs.comiteeMeetingID == meetingId).ToList();
                    bool hasActivePresentations = existingSchedules.Any(gs => gs.Status == "Completed" || gs.Status == "In-Progress");

                    if (!hasActivePresentations)
                    {
                        var scheduleIds = existingSchedules.Select(gs => gs.id).ToList();
                        var queues = db.MeetingQueues.Where(q => scheduleIds.Contains(q.scheduleID ?? 0)).ToList();
                        var queueIds = queues.Select(q => q.id).ToList();

                        var queueAttendances = db.MeetingQueueAttendances.Where(qa => queueIds.Contains(qa.meetingQueueID ?? 0)).ToList();
                        db.MeetingQueueAttendances.RemoveRange(queueAttendances);

                        db.MeetingQueues.RemoveRange(queues);

                        var attendances = db.MeetingAttendances.Where(ma => scheduleIds.Contains(ma.scheduleID ?? 0)).ToList();
                        db.MeetingAttendances.RemoveRange(attendances);

                        db.GroupSchedules.RemoveRange(existingSchedules);
                        db.SaveChanges();

                        var enrolledStudents = db.Enrollments
                            .Where(e => e.subject == type && e.sessionID == model.sessionID)
                            .Select(e => e.studentID)
                            .Distinct()
                            .ToList();

                        if (enrolledStudents.Any())
                        {
                            var groups = (
                                from g in db.ProjectGroups
                                join u in db.Users on g.supervisorID equals u.id into sup
                                from supervisor in sup.DefaultIfEmpty()
                                where enrolledStudents.Contains(g.createdBy)
                                select new GroupScheduleVM
                                {
                                    GroupID = g.id,
                                    SupervisorID = g.supervisorID,
                                    SupervisorName = supervisor != null ? supervisor.name : null
                                }
                            ).ToList();

                            if (groups.Any())
                            {
                                List<GroupScheduleVM> orderedGroups;

                                if (type == "FYP-1")
                                {
                                    var withSupervisor = groups
                                        .Where(g => g.SupervisorID != null)
                                        .OrderBy(g => g.SupervisorName)
                                        .ToList();

                                    var withoutSupervisor = groups
                                        .Where(g => g.SupervisorID == null)
                                        .OrderBy(g => g.GroupID)
                                        .ToList();

                                    orderedGroups = withSupervisor.Concat(withoutSupervisor).ToList();
                                }
                                else
                                {
                                    orderedGroups = groups
                                        .OrderBy(g => g.SupervisorName)
                                        .ThenBy(g => g.GroupID)
                                        .ToList();
                                }

                                var dayMap = new Dictionary<string, DayOfWeek>
                                {
                                    { "Mon", DayOfWeek.Monday },
                                    { "Tue", DayOfWeek.Tuesday },
                                    { "Wed", DayOfWeek.Wednesday },
                                    { "Thu", DayOfWeek.Thursday },
                                    { "Fri", DayOfWeek.Friday },
                                    { "Sat", DayOfWeek.Saturday },
                                    { "Sun", DayOfWeek.Sunday }
                                };

                                var selectedDayEnums = model.selectedDays
                                    .Where(d => dayMap.ContainsKey(d))
                                    .Select(d => dayMap[d])
                                    .ToList();
                                var validDates = new List<DateTime>();
                                DateTime tempDate = model.startDate;

                                while (tempDate <= model.endDate)
                                {
                                    if (selectedDayEnums.Contains(tempDate.DayOfWeek))
                                        validDates.Add(tempDate);

                                    tempDate = tempDate.AddDays(1);
                                }

                                if (validDates.Any())
                                {
                                    int totalGroups = orderedGroups.Count;
                                    int totalDays = validDates.Count;

                                    int groupsPerDay = totalGroups / totalDays;
                                    int extraGroups = totalGroups % totalDays;

                                    int totalMinutesPerDay = (int)(model.endTime - model.startTime).TotalMinutes;
                                    int minutesPerGroup = totalMinutesPerDay / (groupsPerDay == 0 ? 1 : groupsPerDay);

                                    if (minutesPerGroup <= 0) minutesPerGroup = 15;

                                    int groupIndex = 0;

                                    foreach (var date in validDates)
                                    {
                                        TimeSpan currentTime = model.startTime;
                                        int todaysGroups = groupsPerDay;

                                        if (extraGroups > 0)
                                        {
                                            todaysGroups++;
                                            extraGroups--;
                                        }

                                        for (int i = 0; i < todaysGroups; i++)
                                        {
                                            if (groupIndex >= orderedGroups.Count)
                                                break;

                                            var group = orderedGroups[groupIndex];

                                            db.GroupSchedules.Add(new GroupSchedule
                                            {
                                                groupID = group.GroupID,
                                                comiteeMeetingID = meetingId,
                                                estimatedTime = currentTime,
                                                meetingDate = date,
                                                Status = "Waiting",
                                                filePath = null,
                                                isAttend = 0,
                                                type = type
                                            });

                                            currentTime = currentTime.Add(TimeSpan.FromMinutes(minutesPerGroup));
                                            groupIndex++;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                db.SaveChanges();
                return Ok(new { message = "Meeting updated successfully" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpDelete]
        [Route("{meetingId}")]
        public IHttpActionResult DeleteMeeting(int meetingId)
        {
            try
            {
                var meeting = db.ComiteeMeetings.Find(meetingId);
                if (meeting == null)
                    return NotFound();

                var schedules = db.GroupSchedules.Where(gs => gs.comiteeMeetingID == meetingId).ToList();
                var scheduleIds = schedules.Select(gs => gs.id).ToList();

                var queues = db.MeetingQueues.Where(q => scheduleIds.Contains(q.scheduleID ?? 0)).ToList();
                var queueIds = queues.Select(q => q.id).ToList();

                var queueAttendances = db.MeetingQueueAttendances.Where(qa => queueIds.Contains(qa.meetingQueueID ?? 0)).ToList();
                db.MeetingQueueAttendances.RemoveRange(queueAttendances);

                db.MeetingQueues.RemoveRange(queues);

                var attendances = db.MeetingAttendances.Where(ma => scheduleIds.Contains(ma.scheduleID ?? 0)).ToList();
                db.MeetingAttendances.RemoveRange(attendances);

                db.GroupSchedules.RemoveRange(schedules);

                var fyp1Mappings = db.MeetingParameterMappings.Where(m => m.meetingID == meetingId).ToList();
                db.MeetingParameterMappings.RemoveRange(fyp1Mappings);

                var fyp2Mappings = db.Fyp2MeetingMapping.Where(m => m.meetingID == meetingId).ToList();
                db.Fyp2MeetingMapping.RemoveRange(fyp2Mappings);

                db.ComiteeMeetings.Remove(meeting);
                db.SaveChanges();

                return Ok(new { message = "Meeting deleted successfully" });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        public class NotificationRecipients
        {
            public int ID { get; set; }

            public int NotificationID { get; set; }

            public string RecipientID { get; set; }
            public string RecipientRole { get; set; }

            public int IsRead { get; set; }
            public DateTime? ReadAt { get; set; }
        }
        public class GroupScheduleVM
        {
            public int GroupID { get; set; }
            public string SupervisorID { get; set; }
            public string SupervisorName { get; set; }
        }
        [HttpGet]
        [Route("evaluation-parameters/{meetingId}/{type}")]
        public IHttpActionResult GetEvaluationParameters(int meetingId, string type)
        {
            try
            {
                var meeting = db.ComiteeMeetings.FirstOrDefault(m => m.id == meetingId);
                if (meeting == null)
                    return BadRequest("Meeting not found");

                List<EvaluationParameterDto> parameters = new List<EvaluationParameterDto>();

                if (type.ToUpper() == "FYP-1")
                {
                    // 1. Try explicit mapping first
                    var parameterIds = db.MeetingParameterMappings
                        .Where(x => x.meetingID == meetingId)
                        .Select(x => x.parameterID)
                        .ToList();

                    if (parameterIds.Any())
                    {
                        parameters = db.Fyp1EvaluationParameters
                            .Where(p => parameterIds.Contains(p.id))
                            .Select(p => new EvaluationParameterDto
                            {
                                ParameterID = p.id,
                                ParameterName = p.name,
                                Percentage = (decimal)p.percentage,
                                IsGraded = meeting.isGraded == true
                            })
                            .ToList();
                    }
                    else
                    {
                        // 2. Fallback to clean fuzzy matching
                        string cleanTitle = meeting.title.ToLower().Replace(" ", "").Trim();
                        parameters = db.Fyp1EvaluationParameters
                            .Where(p => p.sessionID == meeting.sessionID)
                            .ToList()
                            .Where(p => {
                                string cleanName = p.name.ToLower().Replace(" ", "").Trim();
                                return cleanName == cleanTitle || cleanName.Contains(cleanTitle) || cleanTitle.Contains(cleanName);
                            })
                            .Select(p => new EvaluationParameterDto
                            {
                                ParameterID = p.id,
                                ParameterName = p.name,
                                Percentage = (decimal)p.percentage,
                                IsGraded = meeting.isGraded == true
                            })
                            .ToList();
                    }
                }
                else
                {
                    // 1. Try explicit mapping first
                    var parameterIds = db.Fyp2MeetingMapping
                        .Where(x => x.meetingID == meetingId)
                        .Select(x => x.parameterID)
                        .ToList();

                    if (parameterIds.Any())
                    {
                        parameters = db.Fyp2EvaluationParameters
                            .Where(p => parameterIds.Contains(p.id))
                            .Select(p => new EvaluationParameterDto
                            {
                                ParameterID = p.id,
                                ParameterName = p.name,
                                Percentage = (decimal)p.percentage,
                                IsGraded = meeting.isGraded == true
                            })
                            .ToList();
                    }
                    else
                    {
                        // 2. Fallback to clean fuzzy matching
                        string cleanTitle = meeting.title.ToLower().Replace(" ", "").Trim();
                        parameters = db.Fyp2EvaluationParameters
                            .Where(p => p.sessionID == meeting.sessionID)
                            .ToList()
                            .Where(p => {
                                string cleanName = p.name.ToLower().Replace(" ", "").Trim();
                                return cleanName == cleanTitle || cleanName.Contains(cleanTitle) || cleanTitle.Contains(cleanName);
                            })
                            .Select(p => new EvaluationParameterDto
                            {
                                ParameterID = p.id,
                                ParameterName = p.name,
                                Percentage = (decimal)p.percentage,
                                IsGraded = meeting.isGraded == true
                            })
                            .ToList();
                    }
                }

                return Ok(parameters);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
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
            public int? id { get; set; } // 👈 Add this
            public string name { get; set; }
            public int percentage { get; set; }
        }



        public class RescheduleMeetingDto
        {
            public int MeetingId { get; set; }
            public int GroupId { get; set; }
            public string StudentId { get; set; }
            public DateTime NewDate { get; set; }
            public string NewTime { get; set; }
        }

        public class ScheduleCommitteeMeetingDto
        {
            public string meetingDescription { get; set; }
            public string title { get; set; }

            public DateTime startDate { get; set; }
            public DateTime endDate { get; set; }
            public TimeSpan startTime { get; set; }
            public TimeSpan endTime { get; set; }
            public string venue { get; set; }
            public List<string> selectedDays { get; set; } // ["mon","wed","fri"]
            public int sessionID { get; set; }
            public bool isGraded { get; set; }
            public bool isFileRequired { get; set; }
        }
        public class SupervisorGroupCountDto
        {
            public string SupervisorId { get; set; }
            public string SupervisorName { get; set; }
            public int TotalGroups { get; set; }
        }

        public class ProjectSessionDto
        {
            public int ProjectId { get; set; }
            public string Title { get; set; }
            public string SuggestedBy { get; set; }
            public string Objectives { get; set; }
        }
        public class ProjectAllocate
        {

            public int groupId { get; set; }
            public int projectId { get; set; }

        }
        public class MeetingTimeUpdateModel
        {
            public int ComiteeMeetingID { get; set; }
            public TimeSpan EstimatedTime { get; set; }
            public int GroupID { get; set; }    
        }
        public class SupervisorAllocate
        {

            public int groupId { get; set; }
            public string supervisorId { get; set; }
        }

        /**
         * ATOMIC RE-INDEX ENGINE (Isolated Version)
         * This method re-calculates the entire timeline for a session.
         * By passing 'meetingId', we ensure that different evaluation panels (even for the same Phase)
         * have independent, non-mixed timelines.
         */
        private void ReindexQueue(string type, int? meetingId = null)
        {
            var today = DateTime.Today;
            var now = DateTime.Now;

            // 1. Calculate Real Pace for THIS specific meeting room
            var completedQuery = db.GroupSchedules
                .Where(g => g.type == type && g.meetingDate == today && g.Status == "Completed" && g.isAttend > 1);
            
            if (meetingId.HasValue)
                completedQuery = completedQuery.Where(g => g.comiteeMeetingID == meetingId.Value);

            var completedGroups = completedQuery.ToList();
            int avg = completedGroups.Any() ? (int)completedGroups.Average(g => g.isAttend ?? 20) : 20;

            // 2. Find the current Live Group (In-Progress) in THIS room
            var inProgressQuery = db.GroupSchedules
                .Where(g => g.type == type && g.meetingDate == today && g.Status == "In-Progress");

            if (meetingId.HasValue)
                inProgressQuery = inProgressQuery.Where(g => g.comiteeMeetingID == meetingId.Value);

            var inProgressGroup = inProgressQuery.FirstOrDefault();

            // 3. Determine the 'Anchor Time' for THIS room's queue
            DateTime timelineAnchor = now;

            if (inProgressGroup != null && inProgressGroup.estimatedTime.HasValue)
            {
                DateTime startTime = today.Add(inProgressGroup.estimatedTime.Value);
                DateTime expectedFinish = startTime.AddMinutes(avg);
                timelineAnchor = expectedFinish > now ? expectedFinish : now;
            }

            // 4. Get all Waiting groups for THIS specific meeting
            var waitingQuery = db.GroupSchedules
                .Where(g => g.type == type && g.meetingDate == today && g.Status == "Waiting");

            if (meetingId.HasValue)
                waitingQuery = waitingQuery.Where(g => g.comiteeMeetingID == meetingId.Value);

            var waitingGroups = waitingQuery.OrderBy(g => g.estimatedTime).ToList();

            if (!waitingGroups.Any()) return;

            // 5. Re-map the timeline for THIS room
            foreach (var group in waitingGroups)
            {
                group.estimatedTime = timelineAnchor.TimeOfDay;
                timelineAnchor = timelineAnchor.AddMinutes(avg);
            }

            db.SaveChanges();
        }
        public class UpdateGroupAttendanceDto
        {
            public int GroupId { get; set; }
            public int MeetingId { get; set; }
            public bool IsAttended { get; set; }
        }
        public class UpdateStudentAttendanceDto
        {
            public string studentId { get; set; }
            public int scheduleId { get; set; }
            public bool isAttended { get; set; }
        }



        public class UpdateGroupStatusDto
        {
            public int GroupId { get; set; }
            public int MeetingId { get; set; }
            public string Status { get; set; }
        }

        private void NotifyRelevantGroups(int meetingId, string fypType, string title, string message, string senderId = null)
        {
            try
            {
                // 1. Create the master notification
                var notification = new Notification
                {
                    Title = title,
                    Message = message,
                    Type = "CommitteeMeeting",
                    ReferenceID = meetingId,
                    CreatedAt = DateTime.Now,
                    SenderID = senderId,
                    SenderRole = "Committee"
                };
                db.Notifications.Add(notification);
                db.SaveChanges();

                // 2. Find all groups and their members/supervisors for this meeting
                var groupInfo = db.GroupSchedules
                    .Where(gs => gs.comiteeMeetingID == meetingId)
                    .Select(gs => new {
                        gs.groupID,
                        SupervisorID =  db.ProjectGroups.Where(p => p.id == gs.groupID).Select(s => s.supervisorID).FirstOrDefault(),
                    }).ToList();

                foreach (var info in groupInfo)
                {
                    // Notify Supervisor
                    if (!string.IsNullOrEmpty(info.SupervisorID))
                    {
                        db.NotificationRecipients.Add(new NotificationRecipient {
                            NotificationID = notification.NotificationID,
                            RecipientID = info.SupervisorID,
                            RecipientRole = "Supervisor",
                            IsRead = 0
                        });
                    }

                    // Notify Students
                    var members = db.GroupMembers.Where(gm => gm.groupID == info.groupID).Select(gm => gm.studentID).ToList();
                    foreach (var studentId in members)
                    {
                        db.NotificationRecipients.Add(new NotificationRecipient {
                            NotificationID = notification.NotificationID,
                            RecipientID = studentId,
                            RecipientRole = "Student",
                            IsRead = 0
                        });
                    }
                }
                db.SaveChanges();
            }
            catch { /* Silent fail */ }
        }

        [HttpGet]
        [Route("schedule/{scheduleId}")]
        public IHttpActionResult GetScheduleDetails(int scheduleId)
        {
            var schedule = db.GroupSchedules
                .Where(s => s.id == scheduleId)
                .Select(s => new
                {
                    scheduleId = s.id,
                    meetingId = s.comiteeMeetingID,
                    groupId = s.groupID,
                    title = s.ComiteeMeeting.title,
                    date = s.meetingDate,
                    time = s.estimatedTime,
                    status = s.Status,
                    isGraded = s.ComiteeMeeting.isGraded,
                    isFileRequired = s.ComiteeMeeting.isFileRequired,
                    filePath = s.filePath,
                    type = s.type,
                    description = s.ComiteeMeeting.meetingDescription
                })
                .FirstOrDefault();

            if (schedule == null)
                return NotFound();

            return Ok(schedule);
        }

        [HttpPost]
        [Route("upload-ppt")]
        public IHttpActionResult UploadPpt()
        {
            if (!Request.Content.IsMimeMultipartContent())
                return BadRequest("Invalid request format. Use Multipart/Form-Data.");

            var httpRequest = System.Web.HttpContext.Current.Request;
            if (httpRequest.Files.Count == 0)
                return BadRequest("File is required.");

            var postedFile = httpRequest.Files["file"];
            if (postedFile == null)
                return BadRequest("File is required.");

            if (string.IsNullOrEmpty(httpRequest["scheduleId"]))
                return BadRequest("Schedule ID is required.");

            int scheduleId = Convert.ToInt32(httpRequest["scheduleId"]);

            var schedule = db.GroupSchedules.Find(scheduleId);
            if (schedule == null)
                return NotFound();

            string folderPath = System.Web.HttpContext.Current.Server.MapPath("~/Uploads/CommitteeMeetings/");
            if (!System.IO.Directory.Exists(folderPath))
                System.IO.Directory.CreateDirectory(folderPath);

            string fileName = $"schedule_{scheduleId}_{DateTime.Now.Ticks}{System.IO.Path.GetExtension(postedFile.FileName)}";
            string filePath = System.IO.Path.Combine(folderPath, fileName);

            postedFile.SaveAs(filePath);

            string virtualPath = $"/Uploads/CommitteeMeetings/{fileName}";
            schedule.filePath = virtualPath;

            db.SaveChanges();

            return Ok(new
            {
                Message = "File uploaded successfully.",
                FilePath = virtualPath
            });
        }

        [HttpGet]
        [Route("today-supervisor-meetings/{supervisorId}")]
        public IHttpActionResult GetTodaySupervisorMeetings(string supervisorId)
        {
            try
            {
                var todayStart = DateTime.Today.Date;
                var todayEnd = todayStart.AddDays(1);
                
                // Fetch scheduled committee meetings that are active OR scheduled for today
                var groupSchedules = db.GroupSchedules
                    .Where(gs => gs.Status != "Completed" || 
                                 (gs.meetingDate.HasValue && gs.meetingDate.Value >= todayStart && gs.meetingDate.Value < todayEnd))
                    .ToList();

                var supervisorGroupIds = db.ProjectGroups
                    .Where(pg => pg.supervisorID == supervisorId)
                    .Select(pg => pg.id)
                    .ToList();

                var filteredSchedules = groupSchedules
                    .Where(gs => {
                        var comiteeMeeting = db.ComiteeMeetings.Find(gs.comiteeMeetingID);
                        bool isMidTask = comiteeMeeting != null && 
                                         (comiteeMeeting.title.ToLower().Contains("midtask") || 
                                          comiteeMeeting.title.ToLower().Contains("mid task"));
                        return gs.groupID.HasValue && supervisorGroupIds.Contains(gs.groupID.Value) && isMidTask;
                    })
                    .ToList();

                var result = filteredSchedules.Select(gs => {
                    var comiteeMeeting = db.ComiteeMeetings.Find(gs.comiteeMeetingID);
                    int currentSessionId = comiteeMeeting?.sessionID ?? (db.Sessions.OrderByDescending(o => o.id).FirstOrDefault()?.id ?? 0);
                    
                    // Get project title safely
                    var pg = db.ProjectGroups.Find(gs.groupID);
                    string projectTitle = "No Project Title";
                    if (pg != null && pg.projectID.HasValue)
                    {
                        var offeredProj = db.OfferedProjects.Find(pg.projectID.Value);
                        if (offeredProj != null && offeredProj.projectID.HasValue)
                        {
                            var proj = db.Projects.Find(offeredProj.projectID.Value);
                            if (proj != null)
                            {
                                projectTitle = proj.title;
                            }
                        }
                    }

                    // Get members safely with materialization
                    var members = db.GroupMembers
                        .Where(gm => gm.groupID == gs.groupID)
                        .ToList()
                        .Select(gm => {
                            var student = db.Students.Find(gm.studentID);
                            var enrollment = db.Enrollments
                                .FirstOrDefault(e => e.studentID == gm.studentID && e.sessionID == currentSessionId);
                            
                            var finalTask = db.Fyp2Task
                                .FirstOrDefault(t => t.groupId == gs.groupID && t.sessionID == currentSessionId && t.taskTitle == "Final Task");
                            var midTask = db.Fyp2Task
                                .FirstOrDefault(t => t.groupId == gs.groupID && t.sessionID == currentSessionId && t.taskTitle == "MidTask");

                            return new {
                                studentID = gm.studentID,
                                name = student?.name ?? "Unknown",
                                regNum = student?.regNum ?? "",
                                EnrollmentID = enrollment?.id ?? 0,
                                FinalTaskId = finalTask?.id ?? 0,
                                MidTaskId = midTask?.id ?? 0
                            };
                        }).ToList();

                    bool isMidTask = comiteeMeeting != null && comiteeMeeting.title.ToLower().Contains("midtask");

                    return new {
                        scheduleId = gs.id,
                        meetingId = gs.comiteeMeetingID,
                        groupId = gs.groupID,
                        meetingTitle = comiteeMeeting?.title ?? "No Title",
                        meetingDescription = comiteeMeeting?.meetingDescription ?? "",
                        meetingDate = gs.meetingDate,
                        meetingTime = gs.estimatedTime,
                        venue = comiteeMeeting?.venue ?? "",
                        status = gs.Status,
                        type = gs.type,
                        projectName = projectTitle,
                        isMidTask = isMidTask,
                        members = members
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
    }
}
