using ProgressMonitoringProject.Models;
using System.Linq;
using System.Web.Http;

public class TechnologyController : ApiController
{
    FypProjectProgDBEntities db = new FypProjectProgDBEntities();

    [HttpGet]
    public IHttpActionResult GetAll()
    {
        return Ok(db.Technologies.ToList());
    }

    [HttpGet]
    public IHttpActionResult Get(int id)
    {
        var data = db.Technologies.Find(id);
        if (data == null) return NotFound();
        return Ok(data);
    }

    [HttpPost]
    public IHttpActionResult Add(Technology model)
    {
        db.Technologies.Add(model);
        db.SaveChanges();
        return Ok("Technology Added");
    }

    [HttpPut]
    public IHttpActionResult Update(int id, Technology model)
    {
        var data = db.Technologies.Find(id);
        if (data == null) return NotFound();
        db.Entry(data).CurrentValues.SetValues(model);
        db.SaveChanges();
        return Ok("Technology Updated");
    }

    [HttpDelete]
    public IHttpActionResult Delete(int id)
    {
        var data = db.Technologies.Find(id);
        if (data == null) return NotFound();

        db.Technologies.Remove(data);
        db.SaveChanges();
        return Ok("Technology Deleted");
    }
}
