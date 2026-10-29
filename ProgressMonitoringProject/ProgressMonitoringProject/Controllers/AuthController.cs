using OfficeOpenXml;
using ProgressMonitoringProject.Models;
using System;
using System.Linq;
using System.Web;
using System.Web.Http;

namespace ProgressMonitoringProject.Controllers
{
    [RoutePrefix("api/auth")]
    public class AuthController : ApiController
    {
        private readonly FypProjectProgDBEntities db = new FypProjectProgDBEntities();

        [HttpPost, Route("login")]
        public IHttpActionResult Login([FromBody] LoginRequest req)
        {
            if (req == null || string.IsNullOrEmpty(req.Id) || string.IsNullOrEmpty(req.Password))
                return BadRequest("Invalid credentials payload.");

            var user = db.Users.Find(req.Id);
            if (user == null) return Unauthorized();

            if (user.password != req.Password) return Unauthorized();

            var token = Guid.NewGuid().ToString("N");

            var res = new
            {
                token = token,
                user = new
                {
                    id = user.id,
                    name = user.name,
                    email = user.email,
                    role = user.role
                }
            };

            return Ok(res);
        }

        [HttpPost, Route("change-password")]
        public IHttpActionResult ChangePassword([FromBody] ChangePasswordRequest req)
        {
            if (req == null || string.IsNullOrEmpty(req.Id) || string.IsNullOrEmpty(req.OldPassword) || string.IsNullOrEmpty(req.NewPassword))
                return BadRequest("Invalid payload.");

            var user = db.Users.Find(req.Id);
            if (user == null) return NotFound();

            if (user.password != req.OldPassword) return BadRequest("Old password is incorrect.");

            user.password = req.NewPassword;
            db.Entry(user).State = System.Data.Entity.EntityState.Modified;
            db.SaveChanges();

            return Ok(new { message = "Password changed successfully." });
        }

        [HttpPost]
        [Route("UploadStudentsData")]
        public IHttpActionResult UploadStudents()
        {
            ExcelPackage.License.SetNonCommercialPersonal("ProgressMonitoringProject");

            try
            {
                if (HttpContext.Current.Request.Files.Count == 0)
                    return BadRequest("No file uploaded");

                var file = HttpContext.Current.Request.Files["file"];

                if (file == null || file.ContentLength == 0)
                    return BadRequest("Invalid file");

                using (var package = new ExcelPackage(file.InputStream))
                {
                    var sheet = package.Workbook.Worksheets.FirstOrDefault();

                    if (sheet == null)
                        return BadRequest("No worksheet found");

                    int rows = sheet.Dimension.End.Row;

                    using (var transaction = db.Database.BeginTransaction())
                    {
                        try
                        {
                            for (int i = 2; i <= rows; i++)
                            {
                                string regNum = sheet.Cells[i, 1].Text?.Trim();

                                if (string.IsNullOrWhiteSpace(regNum))
                                    continue;

                                string name = sheet.Cells[i, 2].Text?.Trim();
                                string email = sheet.Cells[i, 3].Text?.Trim();
                                string genderRaw = sheet.Cells[i, 4].Text?.Trim();
                                double cgpa = double.TryParse(sheet.Cells[i, 5].Text, out var c) ? c : 0;
                                int admissionSession = int.TryParse(sheet.Cells[i, 6].Text, out var s) ? s : 0;
                                string departmentName = sheet.Cells[i, 7].Text?.Trim();
                                string sectionName = sheet.Cells[i, 8].Text?.Trim();

                                string password = sheet.Cells[i, 9].Text?.Trim();
                               


                                // Safely extract only the year (e.g., "2021" from "2021-2025")
                               

                                string subject = sheet.Cells[i, 10].Text?.Trim();

                                int sessionId = int.TryParse(sheet.Cells[i, 11].Text, out var t) ? t : 0;
                                string grade = sheet.Cells[i, 12].Text?.Trim();
                                int semesterNo = int.TryParse(sheet.Cells[i, 13].Text, out var sem) ? sem : 0;

                                // Ensure gender is only 1 character to avoid DB errors
                                string cleanGender = !string.IsNullOrEmpty(genderRaw)
                                    ? genderRaw.Substring(0, 1).ToUpper()
                                    : "M"; // Default fallback

                                // ================= Department =================
                                var department = db.Departments.FirstOrDefault(d => d.name == departmentName);
                                if (department == null && !string.IsNullOrEmpty(departmentName))
                                {
                                    department = new Department { name = departmentName };
                                    db.Departments.Add(department);
                                    db.SaveChanges(); // Save now to get the ID for the Student record
                                }

                                // ================= Section =================
                                var section = db.Sections.FirstOrDefault(sec => sec.name == sectionName);
                                if (section == null && !string.IsNullOrEmpty(sectionName))
                                {
                                    section = new Section { name = sectionName };
                                    db.Sections.Add(section);
                                    db.SaveChanges(); // Save now to get the ID for the Student record
                                }

                                // ================= User =================
                                var user = db.Users.FirstOrDefault(u => u.id == regNum);

                                if (user == null)
                                {
                                    db.Users.Add(new User
                                    {
                                        id = regNum,
                                        name = name,
                                        email = email,
                                        password = password,
                                        role = "Student"
                                    });
                                }
                                else
                                {
                                    user.name = name;
                                    user.email = email;
                                    user.password = password;
                                }

                                // ================= Student =================
                                var student = db.Students.FirstOrDefault(st => st.regNum == regNum);

                                if (student == null)
                                {
                                    db.Students.Add(new Student
                                    {
                                        regNum = regNum,
                                        name = name,
                                        gender = cleanGender,
                                        currentCGPA = (float)cgpa,
                                        admissionSession = admissionSession,
                                        studentDepartment = department?.id ?? 0, // Fallback to 0 if null, prevents crash
                                        studentSection = section?.id,
                                        semesterNo = semesterNo
                                    });
                                }
                                else
                                {
                                    student.name = name;
                                    student.gender = cleanGender;
                                    student.currentCGPA = (float)cgpa;
                                    student.admissionSession = admissionSession;
                                    student.studentDepartment = department?.id ?? student.studentDepartment;
                                    student.studentSection = section?.id;
                                    student.semesterNo = semesterNo;
                                }

                                // ================= Enrollment =================
                                var enrollment = db.Enrollments.FirstOrDefault(e =>
                                    e.studentID == regNum &&
                                    e.sessionID == sessionId &&
                                    e.subject == subject);

                                if (enrollment == null)
                                {
                                    db.Enrollments.Add(new Enrollment
                                    {
                                        studentID = regNum,
                                        sessionID = sessionId,
                                        subject = subject,
                                        grade = grade
                                    });
                                }
                                else
                                {
                                    enrollment.grade = grade;
                                }
                            }

                            // Final save for Users, Students, and Enrollments
                            db.SaveChanges();
                            transaction.Commit();

                            return Ok(new { Message = "Data uploaded successfully" });
                        }
                        catch (System.Data.Entity.Validation.DbEntityValidationException dbEx)
                        {
                            transaction.Rollback();
                            var errorMessages = dbEx.EntityValidationErrors
                                .SelectMany(x => x.ValidationErrors)
                                .Select(x => $"Property: {x.PropertyName}, Error: {x.ErrorMessage}");

                            var fullErrorMessage = string.Join("; ", errorMessages);
                            return BadRequest("Validation Failed: " + fullErrorMessage);
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            // Capture the inner exception which usually has the real SQL error
                            string innerMessage = ex.InnerException != null ? ex.InnerException.InnerException?.Message ?? ex.InnerException.Message : ex.Message;
                            return BadRequest("Database Error: " + innerMessage);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        [HttpPost]
        [Route("UploadUsersExcel")]
        public IHttpActionResult UploadUsersExcel()
        {
            ExcelPackage.License.SetNonCommercialPersonal("ProgressMonitoringProject");

            try
            {
                if (HttpContext.Current.Request.Files.Count == 0)
                    return BadRequest("No file uploaded");

                var file = HttpContext.Current.Request.Files["file"];

                if (file == null || file.ContentLength == 0)
                    return BadRequest("Invalid file");

                using (var package = new ExcelPackage(file.InputStream))
                {
                    var sheet = package.Workbook.Worksheets.FirstOrDefault();
                    if (sheet == null)
                        return BadRequest("No worksheet found");

                    int rows = sheet.Dimension.End.Row;

                    using (var transaction = db.Database.BeginTransaction())
                    {
                        try
                        {
                            for (int i = 2; i <= rows; i++)
                            {
                                string id = sheet.Cells[i, 1].Text?.Trim();
                                string name = sheet.Cells[i, 2].Text?.Trim();
                                string password = sheet.Cells[i, 3].Text?.Trim();
                                string email = sheet.Cells[i, 4].Text?.Trim();
                                string role = sheet.Cells[i, 5].Text?.Trim();

                                if (string.IsNullOrWhiteSpace(id) ||
                                    string.IsNullOrWhiteSpace(role))
                                    continue;

                                // Normalize role
                                role = role.Trim();

                                var user = db.Users.FirstOrDefault(u => u.id == id);

                                if (user == null)
                                {
                                    db.Users.Add(new User
                                    {
                                        id = id,
                                        name = name,
                                        email = email,
                                        password = password,
                                        role = role
                                    });
                                }
                                else
                                {
                                    // Update existing user
                                    user.name = name;
                                    user.email = email;
                                    user.password = password;
                                    user.role = role;
                                }
                            }

                            db.SaveChanges();
                            transaction.Commit();

                            return Ok(new
                            {
                                Message = "Excel uploaded successfully. All users inserted/updated."
                            });
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            return InternalServerError(ex);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing) db.Dispose();
            base.Dispose(disposing);
        }

        #region DTOs
        public class LoginRequest
        {
            public string Id { get; set; }
            public string Password { get; set; }
        }

        public class ChangePasswordRequest
        {
            public string Id { get; set; }
            public string OldPassword { get; set; }
            public string NewPassword { get; set; }
        }
        #endregion
    }
}