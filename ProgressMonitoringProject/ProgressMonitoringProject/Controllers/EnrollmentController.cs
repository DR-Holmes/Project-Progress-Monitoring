using ProgressMonitoringProject.Models;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Data.Entity;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/enrollments")]
    public class EnrollmentController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpGet, Route("")]
        public IHttpActionResult GetAll()
        {
            return Ok(db.Enrollments.ToList());
        }

        [HttpGet, Route("by-student/{regNum}")]
        public IHttpActionResult GetByStudent(string regNum)
        {
            var list = db.Enrollments.Where(x => x.studentID == regNum).ToList();
            return Ok(list);
        }

        [HttpPost, Route("")]
        public IHttpActionResult Create([FromBody] Enrollment e)
        {
            db.Enrollments.Add(e);
            db.SaveChanges();
            return Ok(e);
        }

        [HttpPut, Route("{id}")]
        public IHttpActionResult Update(int id, [FromBody] Enrollment e)
        {
            if (id != e.id) return BadRequest("Id mismatch.");

            db.Entry(e).State = EntityState.Modified;
            db.SaveChanges();
            return Ok(e);
        }


        [HttpDelete, Route("{id}")]
        public IHttpActionResult Delete(int id)
        {
            var enroll = db.Enrollments.Find(id);
            if (enroll == null) return NotFound();

            db.Enrollments.Remove(enroll);
            db.SaveChanges();
            return Ok();
        }

   
        [HttpGet, Route("transcript/{regNum}")]
        public IHttpActionResult Transcript(string regNum)
        {
            var list =  db.Enrollments.Where(x => x.studentID == regNum).ToList();
            return Ok(list);
        }
    }
}
