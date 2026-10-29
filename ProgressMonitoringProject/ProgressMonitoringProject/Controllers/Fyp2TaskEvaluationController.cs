
using ProgressMonitoringProject.Models;
using System.Data.Entity;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/fyp2-evaluations")]
    public class Fyp2TaskEvaluationController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        //[HttpGet, Route("")]
        //public async Task<IHttpActionResult> GetAll() => Ok(await db.Fyp2TaskEvaluation.ToListAsync());

        //[HttpGet, Route("{id}")]
        //public async Task<IHttpActionResult> Get(int id)
        //{
        //    var e = await db.Fyp2TaskEvaluation.FindAsync(id);
        //    if (e == null) return NotFound();
        //    return Ok(e);
        //}

        //[HttpPost, Route("")]
        //public async Task<IHttpActionResult> Create([FromBody] Fyp2TaskEvaluation ev)
        //{
        //    if (!ModelState.IsValid) return BadRequest(ModelState);
        //    db.Fyp2TaskEvaluation.Add(ev);
        //    await db.SaveChangesAsync();
        //    return Ok(ev);
        //}

        //[HttpPut, Route("{id}")]
        //public async Task<IHttpActionResult> Update(int id, [FromBody] Fyp2TaskEvaluation updated)
        //{
        //    if (id != updated.id) return BadRequest("Id mismatch");
        //    db.Entry(updated).State = EntityState.Modified;
        //    await db.SaveChangesAsync();
        //    return Ok(updated);
        //}

        //[HttpDelete, Route("{id}")]
        //public async Task<IHttpActionResult> Delete(int id)
        //{
        //    var e = await db.Fyp2TaskEvaluation.FindAsync(id);
        //    if (e == null) return NotFound();
        //    db.Fyp2TaskEvaluation.Remove(e);
        //    await db.SaveChangesAsync();
        //    return Ok();
        //}

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }
}
