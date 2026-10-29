# Security notes

This project was built as an academic prototype. The issues below are known, and are the most valuable things to fix before any real deployment. Contributions are welcome.

| # | Issue | Where | Suggested fix |
|---|---|---|---|
| 1 | Passwords are stored and compared in **plain text** | `Users.password`; `AuthController` (login, change-password, Excel import) | Hash with a slow salted hash (PBKDF2, bcrypt or Argon2); migrate on next login |
| 2 | `login` returns a random GUID token that is never stored or validated, and no endpoint uses `[Authorize]` | `AuthController`, all controllers | Issue signed tokens (JWT) or server-side sessions and enforce them |
| 3 | The API does not check the caller's role; access control is only which screens the client shows | all controllers | Role-based authorisation on every endpoint |
| 4 | CORS allows a single development origin | `App_Start/WebApiConfig.cs` | Configure per environment |
| 5 | `debug="true"` in `Web.config` | `Web.config` | Use `Web.Release.config` transforms |
| 6 | Cleartext HTTP in the default client config | `lib/api_config.dart` | HTTPS in production |
| 7 | Uploaded files are saved under the web root | `Uploads/` | Validate type and size; store outside the web root |

## Secrets

No credentials are committed. The connection string in `Web.config` targets a local SQL Server Express instance with integrated security. Keep real credentials in environment-specific config transforms or a secrets store, never in git.

## Reporting a vulnerability

Open a GitHub issue labelled `security` (without exploit details or real data), or contact the maintainers through their GitHub profiles.
