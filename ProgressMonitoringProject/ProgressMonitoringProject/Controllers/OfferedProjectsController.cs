using ProgressMonitoringProject.Models;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/offered-projects")]
    public class OfferedProjectsController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet, Route("")]
        public async Task<IHttpActionResult> GetAll()
        {
            return Ok(await db.OfferedProjects.ToListAsync());
        }

        [HttpGet, Route("{id}")]
        public async Task<IHttpActionResult> Get(int id)
        {
            var item = await db.OfferedProjects.FindAsync(id);
            if (item == null) return NotFound();
            return Ok(item);
        }

        [HttpGet, Route("by-session/{sessionId}")]
        public async Task<IHttpActionResult> GetBySession(int sessionId)
        {
            var list = await db.OfferedProjects.Where(x => x.sessionID == sessionId).ToListAsync();
            return Ok(list);
        }

        [HttpPost, Route("")]
        public async Task<IHttpActionResult> Create([FromBody] OfferedProject op)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            db.OfferedProjects.Add(op);
            await db.SaveChangesAsync();
            return Ok(op);
        }

        [HttpPut, Route("{id}")]
        public async Task<IHttpActionResult> Update(int id, [FromBody] OfferedProject updated)
        {
            if (id != updated.id) return BadRequest("Id mismatch");
            db.Entry(updated).State = EntityState.Modified;
            await db.SaveChangesAsync();
            return Ok(updated);
        }

        [HttpDelete, Route("{id}")]
        public async Task<IHttpActionResult> Delete(int id)
        {
            var item = await db.OfferedProjects.FindAsync(id);
            if (item == null) return NotFound();
            db.OfferedProjects.Remove(item);
            await db.SaveChangesAsync();
            return Ok();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }
    }
}
