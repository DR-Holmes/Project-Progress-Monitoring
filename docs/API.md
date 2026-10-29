# API reference

Base URL: `/ProgressMonitoringProject/api`. JSON in and out. Generated from the attribute routes in `Controllers/`; commented-out routes are excluded.

> There is currently no authentication enforcement on these endpoints. See [SECURITY.md](SECURITY.md).

## Auth

| Method | Path |
|---|---|
| POST | `/api/auth/login` |
| POST | `/api/auth/change-password` |
| POST | `/api/auth/UploadStudentsData` |
| POST | `/api/auth/UploadUsersExcel` |

## CommitteeMeetings

| Method | Path |
|---|---|
| GET | `/api/committee-meetings/meetings/{meetingId}` |
| GET | `/api/committee-meetings/HeadMeetings` |
| GET | `/api/committee-meetings/GetCriteriaFyp1/{sessionId}` |
| POST | `/api/committee-meetings/EditCriteriaFyp1/{sessionId}` |
| GET | `/api/committee-meetings/GetCriteriaFyp2/{sessionId}` |
| POST | `/api/committee-meetings/EditCriteriaFyp2/{sessionId}` |
| POST | `/api/committee-meetings/save-criteria` |
| GET | `/api/committee-meetings/GetComitteeMembers` |
| GET | `/api/committee-meetings/EligibleGroups/{regNum}` |
| POST | `/api/committee-meetings/AddStudentToGroup` |
| GET | `/api/committee-meetings/all-students-with-group/{type}` |
| GET | `/api/committee-meetings/groups-details/{groupId}` |
| GET | `/api/committee-meetings/StudentByGroup/{groupId}` |
| GET | `/api/committee-meetings/groups/approved/{activeFyp}` |
| GET | `/api/committee-meetings/Profile` |
| PUT | `/api/committee-meetings/allocateSupervisor` |
| GET | `/api/committee-meetings/group-count` |
| GET | `/api/committee-meetings/today-meetings/{type}/{meetingId?}` |
| GET | `/api/committee-meetings/meetings` |
| GET | `/api/committee-meetings/getSpecificGroup/{groupId}` |
| GET | `/api/committee-meetings/getAllOfferedProjects` |
| PUT | `/api/committee-meetings/allocateProject` |
| GET | `/api/committee-meetings/getAllSupervisors` |
| GET | `/api/committee-meetings/IsProjectAllocate/{groupId}` |
| GET | `/api/committee-meetings/IsSupervisorAllocate/{groupId}` |
| GET | `/api/committee-meetings/EnrolledStudents/{type}` |
| POST | `/api/committee-meetings/update-meeting-times-dynamic` |
| POST | `/api/committee-meetings/handle-delay` |
| POST | `/api/committee-meetings/update-group-attendance` |
| POST | `/api/committee-meetings/update-group-status` |
| POST | `/api/committee-meetings/update-student-attendance` |
| GET | `/api/committee-meetings/get-group-attendance` |
| GET | `/api/committee-meetings/get-student-attendance` |
| POST | `/api/committee-meetings/update-meeting-times` |
| GET | `/api/committee-meetings/today-meetings-priority/{meetingId}` |
| POST | `/api/committee-meetings/reschedule-meeting` |
| GET | `/api/committee-meetings/today-meetings-supervisor-priority/{meetingId}` |
| POST | `/api/committee-meetings/update-queue-order` |
| GET | `/api/committee-meetings/IsAnyFemale/{groupId}` |
| GET | `/api/committee-meetings/get-meeting-data/{meetingId}` |
| GET | `/api/committee-meetings/meeting-distribution-preview` |
| GET | `/api/committee-meetings/my-meetings/{userId}/{fypType}` |
| GET | `/api/committee-meetings/meeting-groups/{meetingId}` |
| POST | `/api/committee-meetings/schedule-meeting` |
| PUT | `/api/committee-meetings/{meetingId}` |
| DELETE | `/api/committee-meetings/{meetingId}` |
| GET | `/api/committee-meetings/evaluation-parameters/{meetingId}/{type}` |
| GET | `/api/committee-meetings/schedule/{scheduleId}` |
| POST | `/api/committee-meetings/upload-ppt` |
| GET | `/api/committee-meetings/today-supervisor-meetings/{supervisorId}` |

## Enrollment

| Method | Path |
|---|---|
| GET | `/api/enrollments` |
| GET | `/api/enrollments/by-student/{regNum}` |
| POST | `/api/enrollments` |
| PUT | `/api/enrollments/{id}` |
| DELETE | `/api/enrollments/{id}` |
| GET | `/api/enrollments/transcript/{regNum}` |

## FYP1Score

| Method | Path |
|---|---|
| POST | `/api/fyp1-scores/assign-parameters-to-meeting` |
| GET | `/api/fyp1-scores/get-remarks/{studentEnrollID}/{evaluatorID}/{sessionID}` |
| POST | `/api/fyp1-scores/save` |
| POST | `/api/fyp1-scores/calculate-final-fyp1` |
| GET | `/api/fyp1-scores/evaluation-panel/{meetingId}` |
| GET | `/api/fyp1-scores/final-score/{studentId}/{meetingId}/{sessionId}` |
| POST | `/api/fyp1-scores/save-final-grades` |
| GET | `/api/fyp1-scores/available-criteria/{sessionId}` |
| GET | `/api/fyp1-scores/getDataForUpdateMarks/{groupId}` |
| POST | `/api/fyp1-scores/save-or-update` |
| GET | `/api/fyp1-scores/get-all-remarks/{enrollId}/{sessionId}` |
| POST | `/api/fyp1-scores/update-evaluation-marks` |
| GET | `/api/fyp1-scores/get-saved-marks/{meetingId}/{parameterId}/{evaluatorId}` |
| GET | `/api/fyp1-scores/student-evaluation-history/{enrollmentId}` |

## FYP2Score

| Method | Path |
|---|---|
| POST | `/api/fyp2-scores/assign-parameters-to-meeting` |
| GET | `/api/fyp2-scores/get/{studentEnrollID}/{meetingID}/{evaluatorID}/{sessionID}` |
| POST | `/api/fyp2-scores/save-or-update` |
| GET | `/api/fyp2-scores/get-remarks/{studentEnrollID}/{evaluatorID}/{sessionID}` |
| POST | `/api/fyp2-scores/save` |
| GET | `/api/fyp2-scores/evaluation-panel/{meetingId}` |
| GET | `/api/fyp2-scores/final-score/{studentId}/{meetingId}/{sessionId}` |
| GET | `/api/fyp2-scores/available-criteria/{sessionId}` |
| GET | `/api/fyp2-scores/getDataForUpdateMarks/{groupId}` |
| POST | `/api/fyp2-scores/update-evaluation-marks` |
| GET | `/api/fyp2-scores/get-saved-marks/{parameterId}/{evaluatorId}` |
| GET | `/api/fyp2-scores/get-all-saved-marks/{parameterId}` |
| GET | `/api/fyp2-scores/groups/{groupId}` |
| GET | `/api/fyp2-scores/student-progress/{studentId}/{type}` |
| POST | `/api/fyp2-scores/assign-task` |
| GET | `/api/fyp2-scores/Getcriteria/{sessionId}` |
| POST | `/api/fyp2-scores/Editcriteria/{sessionId}` |
| POST | `/api/fyp2-scores/save-criteria` |
| POST | `/api/fyp2-scores/calculate-final-fyp2` |
| POST | `/api/fyp2-scores/save-final-grades` |

## Fyp2Task

| Method | Path |
|---|---|
| GET | `/api/fyp2-tasks` |
| GET | `/api/fyp2-tasks/{id}` |
| POST | `/api/fyp2-tasks` |
| PUT | `/api/fyp2-tasks/{id}` |
| DELETE | `/api/fyp2-tasks/{id}` |
| POST | `/api/fyp2-tasks/calculate-final-fyp2` |

## Fyp2TaskEvaluation

Conventional routing: `api/fyp2taskevaluation` (`GET`, `POST`) and `api/fyp2taskevaluation/{id}` (`GET`, `PUT`, `DELETE`).

## GradingAnalysis

| Method | Path |
|---|---|
| GET | `/api/grading-analysis/session-wise` |
| GET | `/api/grading-analysis/supervisor-wise` |
| GET | `/api/grading-analysis/group-wise` |

## GroupMembers

Conventional routing: `api/groupmembers` (`GET`, `POST`) and `api/groupmembers/{id}` (`GET`, `PUT`, `DELETE`).

## Meetings

Conventional routing: `api/meetings` (`GET`, `POST`) and `api/meetings/{id}` (`GET`, `PUT`, `DELETE`).

## Notifications

| Method | Path |
|---|---|
| GET | `/api/notifications/get-all/{userId}` |
| POST | `/api/notifications/mark-read/{notificationId}/{userId}` |

## OfferedProjects

| Method | Path |
|---|---|
| GET | `/api/offered-projects` |
| GET | `/api/offered-projects/{id}` |
| GET | `/api/offered-projects/by-session/{sessionId}` |
| POST | `/api/offered-projects` |
| PUT | `/api/offered-projects/{id}` |
| DELETE | `/api/offered-projects/{id}` |

## ProjectGroup

Conventional routing: `api/projectgroup` (`GET`, `POST`) and `api/projectgroup/{id}` (`GET`, `PUT`, `DELETE`).

## Projects

| Method | Path |
|---|---|
| GET | `/api/projects` |
| GET | `/api/projects/{id}` |
| POST | `/api/projects` |
| PUT | `/api/projects/{id}` |
| DELETE | `/api/projects/{id}` |
| GET | `/api/projects/GetProjAssignData/{groupId}` |
| POST | `/api/projects/SaveProjectAssignment` |

## Students

| Method | Path |
|---|---|
| GET | `/api/students/tasks/{id}` |
| GET | `/api/students/getNotifications/{studentId}` |
| GET | `/api/students/eligible-groups/{studentId}` |
| GET | `/api/students` |
| GET | `/api/students/{regNum}` |
| POST | `/api/students/updatePassword` |
| DELETE | `/api/students/{regNum}` |
| GET | `/api/students/by-department/{depId}` |
| GET | `/api/students/by-session/{sessionId}` |
| GET | `/api/students/by-tech/{techId}` |
| GET | `/api/students/is-in-group/{regNum}` |
| POST | `/api/students/update-technologies/{groupId}` |
| GET | `/api/students/current-semester/{studentId}` |

## SupNotBroadCast

Conventional routing: `api/supnotbroadcast` (`GET`, `POST`) and `api/supnotbroadcast/{id}` (`GET`, `PUT`, `DELETE`).

## SupTaskBroadCast

Conventional routing: `api/suptaskbroadcast` (`GET`, `POST`) and `api/suptaskbroadcast/{id}` (`GET`, `PUT`, `DELETE`).

## SuperVisorAttendance

Conventional routing: `api/supervisorattendance` (`GET`, `POST`) and `api/supervisorattendance/{id}` (`GET`, `PUT`, `DELETE`).

## SuperVisor

| Method | Path |
|---|---|
| GET | `/api/supervisor/{supervisorId}` |
| GET | `/api/supervisor/getAllGroups/{selectedFYP}/{supervisorId}` |
| POST | `/api/supervisor/studentAttendance` |
| GET | `/api/supervisor/get-group-members-attendance/{groupId}` |
| GET | `/api/supervisor/GetGroupStudents/{groupId}` |
| POST | `/api/supervisor/update-task-status` |
| GET | `/api/supervisor/supervisorMeetings/{type}` |
| GET | `/api/supervisor/getAllTasks/{supervisorId}/{fypType}` |
| GET | `/api/supervisor/GetSupervisorGroups/{supervisorId}/{fypType}` |
| GET | `/api/supervisor/getSupervisorMeetings/{supervisorId}/{selectedFYP}` |
| GET | `/api/supervisor/group-meetings/{groupId}` |
| GET | `/api/supervisor/get-supervisor-remarks/{studentEnrollID}/{supervisorID}/{meetingID}` |
| GET | `/api/supervisor/get-group-remarks/{groupID}/{supervisorID}/{meetingID}` |
| GET | `/api/supervisor/get-committee-meetings/{groupId}` |
| GET | `/api/supervisor/get-all-remarks-history/{groupId}` |
| GET | `/api/supervisor/get-remarks-history/{groupId}/{studentEnrollId?}` |
| POST | `/api/supervisor/save-supervisor-remarks` |
| POST | `/api/supervisor/schedule-meeting` |
| GET | `/api/supervisor/meetings/{meetingId}` |
| GET | `/api/supervisor/groups/{groupId}` |
| GET | `/api/supervisor/StudentTasks/{groupId}/{studentId}` |
| GET | `/api/supervisor/GroupTasks/{groupId}` |
| POST | `/api/supervisor/assign-task` |
| POST | `/api/supervisor/edit-task` |
| GET | `/api/supervisor/get-supervisor-tasks/{supervisorId}/{fypType}` |
| POST | `/api/supervisor/update-task-progress` |
| POST | `/api/supervisor/evaluate-task` |
| POST | `/api/supervisor/upload-task-ppt` |
| POST | `/api/supervisor/suggest-project` |

## SuperVisorMeeting

| Method | Path |
|---|---|
| POST | `/api/supervisorMeeting/scheduleMeeting` |

## TaskEvaluation

| Method | Path |
|---|---|
| GET | `/api/task-evaluations` |
| GET | `/api/task-evaluations/{id}` |
| PUT | `/api/task-evaluations/mark-completed/{taskId}` |
| PUT | `/api/task-evaluations/{id}` |

## Tasks

Conventional routing: `api/tasks` (`GET`, `POST`) and `api/tasks/{id}` (`GET`, `PUT`, `DELETE`).

## Technology

Conventional routing: `api/technology` (`GET`, `POST`) and `api/technology/{id}` (`GET`, `PUT`, `DELETE`).

## Users

| Method | Path |
|---|---|
| GET | `/api/users` |
| GET | `/api/users/student/{regNum}` |
| GET | `/api/users/by-student/{regNum}` |
| GET | `/api/users/CurrentSession` |
| GET | `/api/users/StudentDetails/{regNum}` |
| GET | `/api/users/StudentByTech/{techName}/{regNum}` |
| POST | `/api/users/CreateGroup` |
| GET | `/api/users/GetMyGroup/{regNum}` |
| POST | `/api/users/RespondGroupRequest` |
| GET | `/api/users/GetGroupRequests/{regNum}` |
| GET | `/api/users/GetMemberRequests/{regNum}` |
| POST | `/api/users/FinalizeGroup` |
| GET | `/api/users/IsFinalized/{regNum}` |
| GET | `/api/users/IsInGroup/{regNum}` |
| GET | `/api/users/IsAdmin/{regNum}` |
| GET | `/api/users/getAllDepartments` |
| GET | `/api/users/getAllSections` |
| DELETE | `/api/users/RemoveGroupMember` |
| POST | `/api/users/UpdateSelectedTech/{id}` |
| POST | `/api/users/CreateGroupRequest` |
| GET | `/api/users/login` |
| GET | `/api/users/allTech` |
| GET | `/api/users/{id}` |
| GET | `/api/users/tech/{id}` |
| POST | `/api/users` |
| PUT | `/api/users/{id}` |
| DELETE | `/api/users/{id}` |
| GET | `/api/users/role/{role}` |
| POST | `/api/users/UpdateGroupRequestStatus` |
