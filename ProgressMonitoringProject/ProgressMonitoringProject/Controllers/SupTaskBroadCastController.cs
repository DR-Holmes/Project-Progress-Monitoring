using ProgressMonitoringProject.Models;
using System.Linq;
using System.Web.Http;

public class SupTaskBroadCastController : ApiController
{
    FypProjectProgDBEntities db = new FypProjectProgDBEntities();

    [HttpGet]
    public IHttpActionResult GetAll()
    {
        return Ok(db.SupTaskBroadCasts.ToList());
    }

    [HttpGet]
    public IHttpActionResult Get(int id)
    {
        var data = db.SupTaskBroadCasts.Find(id);
        if (data == null) return NotFound();

        return Ok(data);
    }

    [HttpPost]
    public IHttpActionResult Add(SupTaskBroadCast model)
    {
        db.SupTaskBroadCasts.Add(model);
        db.SaveChanges();
        return Ok("Task Broadcast Added");
    }

    [HttpPut]
    public IHttpActionResult Update(int id, SupTaskBroadCast model)
    {
        var data = db.SupTaskBroadCasts.Find(id);
        if (data == null) return NotFound();

        db.Entry(data).CurrentValues.SetValues(model);
        db.SaveChanges();
        return Ok("Broadcast Updated");
    }

    [HttpDelete]
    public IHttpActionResult Delete(int id)
    {
        var data = db.SupTaskBroadCasts.Find(id);
        if (data == null) return NotFound();

        db.SupTaskBroadCasts.Remove(data);
        db.SaveChanges();
        return Ok("Deleted Successfully");
    }
}
