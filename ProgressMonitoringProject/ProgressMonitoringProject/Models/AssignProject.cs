using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ProgressMonitoringProject.Models
{
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;

    public class AssignProject
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }

        // Foreign Key to ProjectGroup (studentGroupID)
        [ForeignKey("ProjectGroup")]
        public int studentGroupID { get; set; }

        // Foreign Key to Users (supervisorID)
        [ForeignKey("Supervisor")]
        [Column(TypeName = "varchar(20)")]
        public string supervisorID { get; set; }

        // Foreign Key to OfferedProject (offeredID)
        [ForeignKey("OfferedProject")]
        public int offeredID { get; set; }

        // === Navigation Properties ===

        /// <summary>
        /// The project group this assignment belongs to.
        /// Maps to ProjectGroup table via studentGroupID.
        /// </summary>
        public ProjectGroup ProjectGroup { get; set; }

        /// <summary>
        /// The supervisor assigned to this project.
        /// Maps to Users table via supervisorID.
        /// </summary>
        public User Supervisor { get; set; }

        /// <summary>
        /// The specific offered project details.
        /// Maps to OfferedProject table via offeredID.
        /// </summary>
        public OfferedProject OfferedProject { get; set; }
    }

    // NOTE: Ensure the ProjectGroup, Users, and OfferedProject models 
    // also exist and are correctly defined in your C# project.
}