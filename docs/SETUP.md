# Setup guide

## Prerequisites

| Tool | Version |
|---|---|
| Windows with IIS Express (ships with Visual Studio) | |
| Visual Studio | 2022, "ASP.NET and web development" workload |
| .NET Framework | 4.7.2 targeting pack |
| SQL Server | 2019+ (Express is fine); the script uses compatibility level 160 |
| Flutter SDK | Dart `^3.10` |

## 1. Database

1. Open `database/schema.sql` in SQL Server Management Studio.
2. Run the whole file. It creates `FypProjectProgDB` and all tables, including the FYP-1 criteria tables and `StudentTaskProgress` at the end.
3. The script contains **no data**. See [Seeding users](#seeding-users).

## 2. Backend (ASP.NET Web API)

1. Open `ProgressMonitoringProject/ProgressMonitoringProject.sln`.
2. Restore NuGet packages (automatic on build; `packages/` is not committed).
3. In `ProgressMonitoringProject/Web.config`, edit the connection string `FypProjectProgDBEntities`. The committed default targets a local Express instance:
   ```
   data source=.\SQLEXPRESS;initial catalog=FypProjectProgDB;integrated security=True;...
   ```
   Change `data source` to your server, or use SQL authentication with `user id` and `password`. Never commit real credentials.
4. Run (F5). When hosted in IIS the API is served under `/ProgressMonitoringProject/api` (the project's `IISUrl` is `http://localhost/ProgressMonitoringProject`).
5. To reach it from a phone or emulator, host it in full IIS (or bind IIS Express to your LAN IP) and allow the port through Windows Firewall.
6. CORS is set in `App_Start/WebApiConfig.cs` (default origin `http://localhost:5000`). Change it if you add a browser client.

Uploaded files (tasks, meetings, committee schedules) are written under `ProgressMonitoringProject/Uploads/`. The folder is git-ignored apart from `.gitkeep` files. The app pool identity must be able to write to it.

## 3. Flutter app

```bash
cd project_progress_monitoring
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<host>/ProgressMonitoringProject/api
```

| Target | Host in `API_BASE_URL` |
|---|---|
| Android emulator | `10.0.2.2` (the default) |
| Physical device | your PC's LAN IP |
| Desktop or web on the same machine | `localhost` |

Cleartext `http://` is for local development. Use HTTPS for any real deployment.

## Seeding users

Login (`POST /api/auth/login`) checks the `Users` table: `id`, `name`, `password`, `email`, `role`.

Role values the app understands: `Student`, `Supervisor`, `Committee`, `CommitteeHead`, `QueueHandler`, `DataCell`.

Options:

- **Excel import**: `POST /api/auth/UploadStudentsData` and `POST /api/auth/UploadUsersExcel` accept `.xlsx` files (the Data Cell screens call them). Column order is defined in `Controllers/AuthController.cs`.
- **SQL**: insert a Data Cell user, log in as them, then import the rest:
  ```sql
  INSERT INTO Users (id, name, password, email, role)
  VALUES ('datacell01', 'Data Cell', 'change-me', 'datacell@example.com', 'DataCell');
  ```
  Use a throwaway password; passwords are currently stored in plain text (see [SECURITY.md](SECURITY.md)).

## Troubleshooting

- **App cannot reach the API**: check the base URL and firewall, and that the URL opens in a phone browser.
- **`Login failed for user`**: connection string or SQL authentication mode.
- **Excel import fails**: file must be `.xlsx`; the request size limit is 100 MB (`maxRequestLength` in `Web.config`).
