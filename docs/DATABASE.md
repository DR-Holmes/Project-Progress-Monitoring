# Database overview

SQL Server database `FypProjectProgDB`, created by [`database/schema.sql`](../database/schema.sql) and accessed through Entity Framework 6 (database-first; see `Models/ProjectProgressMonitoring.edmx`).

## Domain areas

| Area | Tables |
|---|---|
| **Identity and academic structure** | `Users` (id, name, password, email, role), `Students`, `Department`, `Section`, `Session`, `Technology`, `Enrollment`, `StudentFypAttempts` |
| **Groups** | `ProjectGroup`, `GroupMembers`, `GroupRequests`, `GroupRequestMembers` |
| **Projects** | `Project`, `OfferedProject` |
| **Tasks** | `Tasks`, `TaskEvaluation`, `StudentTaskProgress`, `Fyp2Task`, `Fyp2TaskEvaluation`, `SupTaskBroadCast` |
| **Meetings** | `SuperVisorMeeting`, `SuperVisorAttendance`, `RecurringMeetingDays`, `ComiteeMeeting`, `GroupSchedule`, `MeetingAttendance`, `SupNotBroadCast` |
| **Evaluation-day queue** | `MeetingQueue`, `MeetingQueueAttendance` |
| **Grading (FYP-1)** | `Fyp1EvaluationParameters`, `Fyp1SubParameter`, `Fyp1ParameterEvaluator`, `Fyp1SessionEvaluation`, `FYP1Evaluators`, `FYP1Score` |
| **Grading (FYP-2)** | `FYP2Score` and the Fyp2 evaluation parameter tables |

## How the pieces relate

- A `Session` (semester) has enrolled `Students` and `OfferedProject`s.
- Students form a `ProjectGroup` through `GroupRequests` and `GroupRequestMembers`; accepted members land in `GroupMembers`. A group has a supervisor (`supervisorID`) and, once allocated, a `Project`.
- Supervisors create `Tasks` for a group or student and meetings in `SuperVisorMeeting`, with attendance in `SuperVisorAttendance`.
- The committee schedules `ComiteeMeeting`s. Each group gets a `GroupSchedule` row, and `MeetingQueue` tracks the group's live state (waiting, in progress, completed) on the day.
- Marks are recorded per evaluator, per criterion, per student (`FYP1Score`, `FYP2Score`) against weighted criteria (`Fyp1SessionEvaluation.percentage`), and the final grade is calculated from them.

## Notes

- The script has no seed data; see [SETUP.md](SETUP.md#seeding-users).
- `Users.password` is plain text (see [SECURITY.md](SECURITY.md)).
- The solution contains two EDMX models (`ProjectProgressMonitoring` and `ProjectProgressMonitoro`); the app's `FypProjectProgDBEntities` connection string points at the first.
