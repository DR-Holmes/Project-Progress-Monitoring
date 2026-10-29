using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity;
using ProgressMonitoringProject;
using ProgressMonitoringProject.Models;   // Your correct EF namespace

public class Db
{
    private readonly FypProjectProgDBEntities _db = new FypProjectProgDBEntities();

    // Get all
    public List<T> GetAll<T>() where T : class
    {
        return _db.Set<T>().ToList();
    }

    // Get by primary key
    public T GetById<T>(int id) where T : class
    {
        return _db.Set<T>().Find(id);
    }

    // Insert
    public bool Insert<T>(T entity) where T : class
    {
        _db.Set<T>().Add(entity);
        return _db.SaveChanges() > 0;
    }

    // Update
    public bool Update<T>(T entity) where T : class
    {
        _db.Entry(entity).State = EntityState.Modified;
        return _db.SaveChanges() > 0;
    }

    // Delete
    public bool Delete<T>(int id) where T : class
    {
        var entity = _db.Set<T>().Find(id);
        if (entity == null)
            return false;

        _db.Set<T>().Remove(entity);
        return _db.SaveChanges() > 0;
    }
}
