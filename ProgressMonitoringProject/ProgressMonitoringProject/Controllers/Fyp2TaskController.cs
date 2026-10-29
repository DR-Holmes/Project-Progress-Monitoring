using ProgressMonitoringProject.Models;
using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/fyp2-tasks")]
    public class Fyp2TaskController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet, Route("")]
        public async Task<IHttpActionResult> GetAll() => Ok(await db.Fyp2Task.ToListAsync());

        [HttpGet, Route("{id}")]
        public async Task<IHttpActionResult> Get(int id)
        {
            var t = await db.Fyp2Task.FindAsync(id);
            if (t == null) return NotFound();
            return Ok(t);
        }

        [HttpPost, Route("")]
        public async Task<IHttpActionResult> Create([FromBody] Fyp2Task task)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            db.Fyp2Task.Add(task);
            await db.SaveChangesAsync();
            return Ok(task);
        }

        [HttpPut, Route("{id}")]
        public async Task<IHttpActionResult> Update(int id, [FromBody] Fyp2Task updated)
        {
            if (id != updated.id) return BadRequest("Id mismatch");
            db.Entry(updated).State = EntityState.Modified;
            await db.SaveChangesAsync();
            return Ok(updated);
        }

        [HttpDelete, Route("{id}")]
        public async Task<IHttpActionResult> Delete(int id)
        {
            var t = await db.Fyp2Task.FindAsync(id);
            if (t == null) return NotFound();
            db.Fyp2Task.Remove(t);
            await db.SaveChangesAsync();
            return Ok();
        }
        [HttpPost]
        [Route("calculate-final-fyp2")]
        public IHttpActionResult CalculateFinalFyp2()
        {
            var data = db.Fyp2StudentEvaluationMarks
                .ToList()
                .GroupBy(m => new { m.studentEnrollID, m.sessionID })
                .Select(g =>
                {
                    var parameterGroups = g.GroupBy(x => x.parameterID);
                    decimal finalScore = 0;
                    foreach (var paramGroup in parameterGroups)
                    {
                        var parameter = db.Fyp2EvaluationParameters
                            .FirstOrDefault(p => p.id == paramGroup.Key);
                        if (parameter == null) continue;
                        decimal obtained = paramGroup.Sum(x => x.obtainedMarks ?? 0);
                        decimal max = paramGroup.Sum(x => x.maxMarks ?? 0);
                        if (max == 0) continue;
                        // FYP 2 schema uses decimal for percentage
                        decimal paramPercentage = parameter.percentage ?? 0;
                        decimal paramScore = (obtained / max) * paramPercentage;
                        finalScore += paramScore;
                    }
                    return new
                    {
                        EnrollmentID = g.Key.studentEnrollID,
                        SessionID = g.Key.sessionID,
                        FinalScore = Math.Round(finalScore, 2),
                        Grade = GetGrade((double)finalScore)
                    };
                })
                .ToList();
            // ✅ SAVE INTO ENROLLMENT
            foreach (var r in data)
            {
                var enrollment = db.Enrollments
                    .FirstOrDefault(e =>
                        e.id == r.EnrollmentID &&
                        e.sessionID == r.SessionID &&
                        e.subject == "FYP-2" // Checking FYP-2 specifically
                    );
                if (enrollment != null)
                {
                    // Assign only the letter to avoid varchar(5) truncation!
                    enrollment.grade = r.Grade;
                }
            }
            db.SaveChanges();
            return Ok(data);
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
