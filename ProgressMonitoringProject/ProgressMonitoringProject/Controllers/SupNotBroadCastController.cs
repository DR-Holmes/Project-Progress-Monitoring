using ProgressMonitoringProject.Models;
using System.Linq;
using System.Web.Http;

public class SupNotBroadCastController : ApiController
{
    FypProjectProgDBEntities db = new FypProjectProgDBEntities();

    [HttpGet]
    public IHttpActionResult GetAll()
    {
        return Ok(db.SupNotBroadCasts.ToList());
    }

    [HttpGet]
    public IHttpActionResult Get(int id)
    {
        var data = db.SupNotBroadCasts.Find(id);
        if (data == null) return NotFound();

        return Ok(data);
    }

    [HttpPost]
    public IHttpActionResult Add(SupNotBroadCast model)
    {
        db.SupNotBroadCasts.Add(model);
        db.SaveChanges();
        return Ok("Notification Broadcast Created");
    }

    [HttpPut]
    public IHttpActionResult Update(int id, SupNotBroadCast model)
    {
        var data = db.SupNotBroadCasts.Find(id);
        if (data == null) return NotFound();

        db.Entry(data).CurrentValues.SetValues(model);
        db.SaveChanges();
        return Ok("Notification Updated");
    }

    [HttpDelete]
    public IHttpActionResult Delete(int id)
    {
        var data = db.SupNotBroadCasts.Find(id);
        if (data == null) return NotFound();

        db.SupNotBroadCasts.Remove(data);
        db.SaveChanges();
        return Ok("Notification Deleted");
    }
}
