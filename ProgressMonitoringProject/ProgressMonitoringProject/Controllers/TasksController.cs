//using ProgressMonitoringProject.Controllers;
//using ProgressMonitoringProject.Models;
//using System;
//using System.Collections.Generic;
//using System.Data.Entity;
//using System.Linq;
//using System.Net.Http;
//using System.Threading.Tasks;
//using System.Web.Http;
//using System.Web.Mvc;
//using HttpDeleteAttribute = System.Web.Http.HttpDeleteAttribute;
//using HttpGetAttribute = System.Web.Http.HttpGetAttribute;
//using HttpPostAttribute = System.Web.Http.HttpPostAttribute;
//using HttpPutAttribute = System.Web.Http.HttpPutAttribute;
//using RouteAttribute = System.Web.Http.RouteAttribute;
//using RoutePrefixAttribute = System.Web.Http.RoutePrefixAttribute;
//using Task = ProgressMonitoringProject.Models.Task;
//[RoutePrefix("api/task")]
//public class TaskController : ApiController
//{
//    FypProjectProgDBEntities db = new FypProjectProgDBEntities();



//    [HttpGet]
//    [Route("GetTasksBySupervisor/{supervisorId}")]
//    public IHttpActionResult GetTasksBySupervisor(string supervisorId)
//    {
//        var tasks = db.Tasks
//            .Where(t => t.assignedBy == supervisorId)
//            .Select(t => new
//            {
//                t.id,
//                t.title,
//                t.taskDescription,
//                t.assignDate,
//                t.dueDate,
//                t.taskStatus,
//                t.isPptRequired,


//                Group = t.groupID != null ? new
//                {
//                    GroupId = t.ProjectGroup.id,
//                    CreatedBy = t.ProjectGroup.createdBy,
//                    SupervisorId = t.ProjectGroup.supervisorID,

//                    Students = t.ProjectGroup.GroupMembers
//                        .Where(gm => gm.requestStatus == true || gm.requestStatus == null)
//                        .Select(gm => new
//                        {
//                            StudentId = gm.Student.regNum,
//                            StudentName = gm.Student.name,
//                            Gender = gm.Student.gender,
//                            DepartmentId = gm.Student.studentDepartment,
//                            DepartmentName = gm.Student.Department != null ? gm.Student.Department.name : null
//                        })
//                        .ToList()
//                } : null,
//            });



//        if (!tasks.Any())
//            return NotFound();

//        return Ok(tasks);
//    }

//    [HttpGet]
//    [Route("getGroupTaskDetails/{groupId}/{status}")]
//    public IHttpActionResult GetGroupTaskDetails(int groupId, string status)

//    {

//        var groupTask = db.Tasks

//            .Where(task => task.groupID == groupId

//                           && task.taskStatus == status

//                           && task.studentID == null)

//            .Select(task => new Task

//            {

//                id = task.id,

//                title = task.title,

//                taskDescription = task.taskDescription,

//                dueDate = task.dueDate,

//                taskStatus = task.taskStatus

//            })

//            .FirstOrDefault();

//        if (groupTask == null)

//            return NotFound();

//        return Ok(groupTask);

//    }


//    [HttpGet]
//    [Route("GetTasksByStudent/{studentId}")]
//    public IHttpActionResult GetTasksByStudent(string studentId)
//    {
//        var tasks = db.Tasks.Where(t => t.studentID == studentId).ToList();

//        if (tasks == null || tasks.Count == 0)
//            return NotFound();

//        return Ok(tasks);
//    }

//    //// Fetch Group Tasks for a given GroupID

//    //[HttpGet]
//    //[Route("api/task/GetGroupTasks/{groupId}")]
//    //public IHttpActionResult GetGroupTasks(int groupId)
//    //{
//    //    var tasks = db.Tasks
//    //        .Where(t => t.groupID == groupId && t.studentID == null)
//    //        .ToList();

//    //    if (!tasks.Any()) return NotFound();

//    //    return Ok(tasks);
//    //}
    

//    [HttpGet]
//    [Route("api/task/GetPendingCount/{studentId}")]
//    public IHttpActionResult GetPendingCount(string studentId)
//    {
//        int pendingCount = db.Tasks
//            .Where(t => t.taskStatus == "Pending" && t.studentID == studentId)
//            .Count();

//        return Ok(pendingCount);
//    }

//    [HttpPost]
//    public IHttpActionResult Add(Task model)
//    {
//        db.Tasks.Add(model);
//        db.SaveChanges();
//        return Ok("Task Added");
//    }


//    [HttpPut]
//    public IHttpActionResult Update(int id, Task model)
//    {
//        var data = db.Tasks.Find(id);
//        if (data == null) return NotFound();

//        db.Entry(data).CurrentValues.SetValues(model);
//        db.SaveChanges();
//        return Ok("Task Updated");
//    }

//    [HttpDelete]
//    public IHttpActionResult Delete(int id)
//    {
//        var data = db.Tasks.Find(id);
//        if (data == null) return NotFound();

//        db.Tasks.Remove(data);
//        db.SaveChanges();
//        return Ok("Task Deleted");
//    }







//    [HttpGet]
//    public IHttpActionResult GetAll()
//    {
//        return Ok(db.Tasks.ToList());
//    }

//    [HttpGet]
//    public IHttpActionResult Get(int id)
//    {
//        var data = db.Tasks.Find(id);
//        if (data == null) return NotFound();
//        return Ok(data);
//    }


    

//    [HttpPost]
//    [Route("add-remarks/{taskId}/{supervisorId}/{remarks}")]
//    public IHttpActionResult AddRemarks(int taskId, string supervisorId, string remarks)
//    {

//        var task = db.Tasks.Find(taskId);
//        if (task == null) return NotFound();


//        if (task.taskStatus != "Pending")
//            return BadRequest("Cannot add remarks. Task is not pending.");


//        if (task.assignedBy != supervisorId)
//            return BadRequest("You are not authorized to add remarks to this task.");


//        TaskEvaluation evaluation = new TaskEvaluation
//        {
//            taskID = taskId,
//            taskRemarks = remarks,
//            submissionFilePath = null,
//            submissionDate = DateTime.Now
//        };

//        db.TaskEvaluations.Add(evaluation);
//        db.SaveChanges();

//        return Ok("Remarks added successfully.");
//    }

  
//    [HttpGet, Route("task-remarks/{taskId}")]
//    public IHttpActionResult GetTaskRemarks(int taskId)
//    {
//        var remarks = db.TaskEvaluations
//            .Where(r => r.taskID == taskId)
//            .OrderByDescending(r => r.submissionDate)
//            .ToList();

//        if (!remarks.Any()) return NotFound();

//        return Ok(remarks);
//    }

   

//    [HttpPut, Route("{id}")]
//    public IHttpActionResult Update(int id, TaskEvaluation updated)
//    {
//        if (id != updated.id)
//            return BadRequest("Evaluation ID mismatch.");

//        db.Entry(updated).State = EntityState.Modified;
//        db.SaveChanges();

//        return Ok("Evaluation updated successfully.");
//    }

 
//    [HttpPost]
//    [Route("upload-file")]
//    public IHttpActionResult UploadFile()
//    {

//        if (!Request.Content.IsMimeMultipartContent())
//            return BadRequest("Invalid request format. Use Multipart/Form-Data.");

//        var httpRequest = System.Web.HttpContext.Current.Request;

//        int taskId = Convert.ToInt32(httpRequest["taskId"]);
//        string studentId = httpRequest["studentId"];

//        var task = db.Tasks.Find(taskId);
//        if (task == null) return NotFound();

//        if (task.studentID != studentId)
//            return BadRequest("You are not authorized to upload file for this task.");

//        var postedFile = httpRequest.Files["file"];
//        if (postedFile == null)
//            return BadRequest("File is required.");


//        string folderPath = System.Web.HttpContext.Current.Server.MapPath("~/Uploads/Tasks/");
//        if (!System.IO.Directory.Exists(folderPath))
//            System.IO.Directory.CreateDirectory(folderPath);


//        string fileName = $"{taskId}_{studentId}_{DateTime.Now.Ticks}{System.IO.Path.GetExtension(postedFile.FileName)}";
//        string filePath = System.IO.Path.Combine(folderPath, fileName);


//        postedFile.SaveAs(filePath);


//        string virtualPath = $"/Uploads/Tasks/{fileName}";


//        var evaluation = db.TaskEvaluations
//            .FirstOrDefault(e => e.taskID == taskId);

//        if (evaluation == null)
//        {

//            evaluation = new TaskEvaluation
//            {
//                taskID = taskId,
//                submissionFilePath = virtualPath,
//                submissionDate = DateTime.Now,
//                taskRemarks = null
//            };
//            db.TaskEvaluations.Add(evaluation);
//        }
//        else
//        {

//            evaluation.submissionFilePath = virtualPath;
//            evaluation.submissionDate = DateTime.Now;
//        }

//        db.SaveChanges();

//        return Ok(new
//        {
//            Message = "File uploaded successfully.",
//            FilePath = virtualPath
//        });
//    }

   
//    [HttpPut, Route("mark-completed/{taskId}")]
//    public IHttpActionResult MarkTaskCompleted(int taskId)
//    {
//        var task = db.Tasks.Find(taskId);

//        if (task == null) return NotFound();

//        task.taskStatus = "Completed";

//         db.SaveChanges();

//        return Ok("Task status updated to Completed.");
//    }
 
//    [HttpGet, Route("completed-tasks-by-supervisor/{supervisorId}")]
//    public IHttpActionResult GetCompletedTasksBySupervisor(string supervisorId)
//    {
//        var completedTasks = db.Tasks
//            .Where(t => t.taskStatus == "Completed" && t.assignedBy == supervisorId)
//            .Include(t => t.Student)
//            .Include(t => t.ProjectGroup)
//            .ToList();

//        if (!completedTasks.Any())
//        {
//            return NotFound();
//        }

//        return Ok(completedTasks);
//    }

//    [HttpGet]
//    [Route("GetGroupTasks/{groupId}")]
//    public IHttpActionResult GetGroupTasks(int groupId)
//    {
//        var tasks = db.Tasks
//            .Where(t => t.groupID == groupId)

//            .GroupJoin(db.Students,
//                       task => task.studentID,
//                       student => student.regNum,
//                       (task, students) => new { Task = task, Students = students })
//            .SelectMany(
//                x => x.Students.DefaultIfEmpty(),
//                (x, student) => new AssignedTaskDto
//                {
//                    TaskId = x.Task.id,
//                    TaskTitle = x.Task.title,

//                    AssignedTo = (x.Task.studentID == null) ? "Whole Group" : student.name,
//                    IsGroupTask = (x.Task.studentID == null)
//                }
//            ).ToList();

//        return Ok(tasks);
//    }
   

//    [HttpPost]
//    [Route("assignTask/{groupId}")]
//    public IHttpActionResult AssignTask(CreateTaskDto input)
//    {
//        var newTask = new Task
//        {
//            title = input.Title,
//            taskDescription = input.Description,
//            groupID = input.GroupId,
//            assignedBy = input.SupervisorId,
//            assignDate = DateTime.Now,
//            dueDate = input.DueDate,
//            taskStatus = "Pending",


//            studentID = input.IsWholeGroup ? null : input.TargetStudentRegNum,
//            isPptRequired = false
//        };

//        db.Tasks.Add(newTask);
//        db.SaveChanges();
//        return Ok("Task Assigned Sucessfully!");
//    }

//    [HttpPut]
//    [Route("updateTask/{groupId}")]
//    public IHttpActionResult UpdateTask(int taskId, CreateTaskDto input)
//    {
//        var taskToUpdate = db.Tasks
//            .Where(t => t.id == taskId)
//            .FirstOrDefault();

//        if (taskToUpdate == null)
//        {
//            return NotFound();
//        }

//        taskToUpdate.title = input.Title;
//        taskToUpdate.taskDescription = input.Description;
//        taskToUpdate.dueDate = input.DueDate;

//        if (input.IsWholeGroup)
//        {
//            taskToUpdate.studentID = null;
//            taskToUpdate.groupID = input.GroupId;
//        }
//        else
//        {
//            taskToUpdate.studentID = input.TargetStudentRegNum;
//            taskToUpdate.groupID = input.GroupId;
//        }


//        db.SaveChanges();
//        return Ok("Task Updated");
//    }




//         [HttpGet]
//         [Route("getGroupTaskByStatus/{groupId}/{studentRegNum}/{status}")]
//        public IHttpActionResult GetGroupTasksByStatus(int groupId, string studentRegNum, string status)
//    {
//        var groupTasks =  db.Tasks
//            .Where(t => t.groupID == groupId && t.studentID == null && t.taskStatus == status)
//            .Select(t => new TaskDto
//            {
//                TaskId = t.id,
//                Title = t.title,
//                Deadline = t.dueDate,
//                IsGroupTask = true,
//                Remarks = db.TaskEvaluations
//                            .Where(te => te.taskID == t.id)
//                            .Select(te => te.taskRemarks)
//                            .FirstOrDefault()
//            }).ToList();

//        var individualTasks =  db.Tasks
//            .Where(t => t.groupID == groupId && t.studentID == studentRegNum && t.taskStatus == status)
//            .Select(t => new TaskDto
//            {
//                TaskId = t.id,
//                Title = t.title,
//                Deadline = t.dueDate,
//                IsGroupTask = false,
//                Remarks = db.TaskEvaluations
//                            .Where(te => te.taskID == t.id)
//                            .Select(te => te.taskRemarks)
//                            .FirstOrDefault()
//            }).ToList();

//        return Ok(new TaskScreenDto
//        {
//            GroupTasks = groupTasks,
//            IndividualTasks = individualTasks
//        });
//    }

  
//    public class TaskScreenDto
//    {
//        public List<TaskDto> GroupTasks { get; set; }
//        public List<TaskDto> IndividualTasks { get; set; }
//    }

//    public class TaskDto
//    {
//        public int TaskId { get; set; }
//        public string Title { get; set; }
//        public DateTime? Deadline { get; set; }
//        public bool IsGroupTask { get; set; }
//        public string Remarks { get; set; } 
//    }


//}
