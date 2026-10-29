using ProgressMonitoringProject.Models;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/task-evaluations")]
    public class TaskEvaluationController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

     
        [HttpGet, Route("")]
        public async Task<IHttpActionResult> GetAll() => Ok(await db.TaskEvaluations.ToListAsync());

     
        [HttpGet, Route("{id}")]
        public async Task<IHttpActionResult> Get(int id)
        {
            var eval = await db.TaskEvaluations.FindAsync(id);
            if (eval == null) return NotFound();
            return Ok(eval);
        }

  
        [HttpPut, Route("mark-completed/{taskId}")]
        public async Task<IHttpActionResult> MarkTaskCompleted(int taskId)
        {
            var task = await db.Tasks.FindAsync(taskId);

            if (task == null) return NotFound();

            task.taskStatus = "Completed";

            await db.SaveChangesAsync();

            return Ok("Task status updated to Completed.");
        }

        
        [HttpPut, Route("{id}")]
        public async Task<IHttpActionResult> Update(int id, TaskEvaluation updated)
        {
            if (id != updated.id)
                return BadRequest("Evaluation ID mismatch.");

            db.Entry(updated).State = EntityState.Modified;
            await db.SaveChangesAsync();

            return Ok("Evaluation updated successfully.");
        }

        

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }
}
