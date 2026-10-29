# BIIT Project Progress Monitoring System

A multi-role platform for running a university **Final Year Project (FYP)** programme end to end: group formation, supervisor and project allocation, task tracking, meeting scheduling, attendance, rubric-based grading and a live evaluation-day queue.

Built as a BS Computer Science final year project at the **Barani Institute of Information Technology (BIIT), PMAS Arid Agriculture University Rawalpindi** (Spring 2026).

## Why

Generic tools (Jira, Trello, Asana, Notion, GitHub Projects) track tasks but know nothing about how an FYP department works. They have no supervisor or committee roles, no weighted evaluation criteria, no attendance records and no way to run a live evaluation-day queue. This system puts all of that in one place, backed by one shared API.

## Features

| Role | What they can do |
|---|---|
| **Student** | Create or join a project group, accept or decline group requests, pick technologies, view tasks and submit deliverables, see meetings and queue status, read notifications |
| **Supervisor** | Allocate and review tasks, schedule and edit meetings, take meeting notes, mark attendance, run mid evaluations, suggest projects, see all supervised groups |
| **Committee** | Allocate groups, supervisors and projects, schedule graded milestone meetings, evaluate groups against weighted criteria, view approved groups |
| **Committee Head** | Everything a committee member can do, plus define FYP-1 and FYP-2 evaluation criteria, allocate general tasks, manage grades and see grading analysis (by session, supervisor and group) |
| **Queue Handler** | Run the live meeting queue on evaluation days: mark attendance and move groups between waiting, in progress and completed |
| **Data Cell** | Bulk-enrol students and users from Excel sheets |

Other highlights:

- Separate **FYP-1** and **FYP-2** flows with their own rubrics, sub-parameters, evaluators and final-score calculation
- Weighted, per-evaluator marks and remarks, with a final grade calculation
- Notification and broadcast system (supervisor to group, committee to everyone)
- Excel import of students and users (EPPlus)
- Grading analysis (session-wise, supervisor-wise, group-wise)

## Architecture

```
 Flutter app (Android / iOS / desktop / web)
            |  JSON over HTTP
            v
 ASP.NET Web API 2 (.NET Framework 4.7.2, attribute routing, CORS)
            |  Entity Framework 6 (database-first, EDMX)
            v
 SQL Server  (FypProjectProgDB)
```

| Path | Contents |
|---|---|
| [`ProgressMonitoringProject/`](ProgressMonitoringProject) | Visual Studio solution: the ASP.NET Web API backend (`Controllers/`, `Models/` EF entities, `App_Start/`) |
| [`project_progress_monitoring/`](project_progress_monitoring) | Flutter client, MVVM layout: `lib/view/<role>ui/` screens and `lib/viewmodels/` |
| [`database/schema.sql`](database/schema.sql) | SQL Server schema script (tables, keys, constraints). No data |
| [`docs/`](docs) | [Setup](docs/SETUP.md), [API reference](docs/API.md), [database overview](docs/DATABASE.md), [security notes](docs/SECURITY.md) |

## Quick start

Full instructions are in [docs/SETUP.md](docs/SETUP.md). In short:

1. **Database**: run `database/schema.sql` on SQL Server (Express is fine).
2. **Backend**: open `ProgressMonitoringProject/ProgressMonitoringProject.sln` in Visual Studio 2022, restore NuGet packages, set the connection string in `Web.config`, run.
3. **Mobile app**:
   ```bash
   cd project_progress_monitoring
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://<host>/ProgressMonitoringProject/api
   ```
4. **Users**: login needs rows in the `Users` table. See [Seeding users](docs/SETUP.md#seeding-users).

## Tech stack

- **Client**: Flutter / Dart 3, Provider, `http`, `file_picker`, `excel`, `dropdown_button2`, `intl`
- **Server**: ASP.NET Web API 2, C#, Entity Framework 6, EPPlus, Newtonsoft.Json
- **Database**: Microsoft SQL Server

## Status and known limitations

This is a working academic project, not a hardened production system. Read [docs/SECURITY.md](docs/SECURITY.md) before any real deployment. In particular: passwords are stored and compared in plain text, login issues a token that endpoints do not yet enforce, and CORS is limited to a development origin. They are listed openly so contributors can fix them.

The accompanying thesis also describes a Next.js web client and a React Native client against the same API. **Those clients are not part of this repository.** Only the backend and the Flutter client are.

## Team

| Name | Reg. no. |
|---|---|
| Raja Muhammad Taha | 22-Arid-4158 |
| Muhammad Sabih Ul Hassan | 22-Arid-4118 |
| Simran Hafeez | 22-Arid-4198 |

Supervisor: Mr. Umar Farooq, BIIT.

## License

[MIT](LICENSE)
