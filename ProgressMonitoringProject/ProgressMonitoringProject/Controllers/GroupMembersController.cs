//using ProgressMonitoringProject.Models;
//using System.Data.Entity;
//using System.Linq;
//using System.Threading.Tasks;
//using System.Web.Http;

//namespace ProgressMonitoringProject.Controllers
//{
//    [RoutePrefix("api/group-members")]
//    public class GroupMembersController : ApiController
//    {
//        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

//        [HttpGet, Route("")]
//        public async Task<IHttpActionResult> GetAll() => Ok(await db.GroupMembers.ToListAsync());

//        [HttpGet, Route("by-group/{groupId}")]
//        public async Task<IHttpActionResult> ByGroup(int groupId)
//        {
//            var list = await db.GroupMembers.Where(g => g.groupID == groupId).ToListAsync();
//            return Ok(list);
//        }

//        [HttpGet, Route("{id}")]
//        public async Task<IHttpActionResult> Get(int id)
//        {
//            var gm = await db.GroupMembers.FindAsync(id);
//            if (gm == null) return NotFound();
//            return Ok(gm);
//        }

//        [HttpPost, Route("")]
//        public async Task<IHttpActionResult> Create([FromBody] GroupMember gm)
//        {
//            if (!ModelState.IsValid) return BadRequest(ModelState);
//            db.GroupMembers.Add(gm);
//            await db.SaveChangesAsync();
//            return Ok(gm);
//        }

//        [HttpDelete, Route("{id}")]
//        public async Task<IHttpActionResult> Delete(int id)
//        {
//            var gm = await db.GroupMembers.FindAsync(id);
//            if (gm == null) return NotFound();
//            db.GroupMembers.Remove(gm);
//            await db.SaveChangesAsync();
//            return Ok();
//        }

        
//        [HttpGet, Route("{id}/eligible-fyp2")]
//        public async Task<IHttpActionResult> CheckEligibility(int id)
//        {
//            var gm = await db.GroupMembers.FindAsync(id);
//            if (gm == null) return NotFound();

//            var scores = await db.FYP1Score.Where(s => s.groupMemberID == gm.id).ToListAsync();
//            if (!scores.Any()) return Ok(new { eligible = false, reason = "No FYP1 scores" });

//            var avg = scores.Average(s => s.score);
//            bool eligible = avg >= 50;
//            return Ok(new { eligible, average = avg });
//        }

//        protected override void Dispose(bool disposing)
//        {
//            if (disposing) db.Dispose();
//            base.Dispose(disposing);
//        }
//    }
//}
