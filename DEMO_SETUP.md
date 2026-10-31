# Institution Platform — English Sample Demo

This is a **local-only portfolio demo**, not a production deployment. It seeds:

- **2 fictional institutions:** BrightPath Learning Center (Example City) and Community Bridge Foundation (Sample Town)
- **3 English announcements** and **2 English upcoming events**
- **1 fixed demo Super Admin account**, provided below for reviewers

The *sample content* is in English. The Flutter interface supports both Arabic and English; changing the sample data does not change the selected interface language.

## Demo Super Admin — test credentials (intentionally public)

| Field | Value |
|---|---|
| Email | `demo.superadmin@example.com` |
| Password | `DemoAdmin2026!` |
| Role | `SUPER_ADMIN` |

**For local demo testing only.** These are intentionally published test credentials, not a real personal account. The demo initializer runs only with the Spring `demo` profile, refuses to seed unless it connects to a localhost PostgreSQL database named `institution_platform_demo`, and binds the demo backend to `127.0.0.1` by default. Do **not** expose this demo backend to the Internet or reuse this password for real accounts.

## Requirements

- Java 21
- Flutter SDK
- Docker Desktop running (the database container)

## 1. Start the demo PostgreSQL database

Open PowerShell in the repository root (the folder containing `backend`, `frontend`, and `docker-compose.demo.yml`):

```powershell
docker compose -f docker-compose.demo.yml up -d
```

The demo PostgreSQL database lives on **127.0.0.1:5433**, separate from your normal local PostgreSQL.

## 2. Start Spring Boot with demo profile

Open a **new** PowerShell window inside the `backend` folder:

```powershell
$env:DB_URL = 'jdbc:postgresql://localhost:5433/institution_platform_demo'
$env:DB_USERNAME = 'demo_user'
$env:DB_PASSWORD = 'demo_local_only'
$env:SPRING_PROFILES_ACTIVE = 'demo'
$env:CORS_ALLOWED_ORIGINS = 'http://localhost:54545'
.\mvnw.cmd spring-boot:run
```

On first startup, the backend inserts the English sample records into an **empty** demo database and creates the fixed demo Super Admin account if it does not already exist.

Verify from the same computer:

```text
http://localhost:8080/api/institutions
```

You should receive two institutions with English names. `http://localhost:8080/api/auth/me` requires authentication; testing it in a normal browser without credentials will not show the admin profile.

## 3. Start the Flutter Web app

Open another PowerShell inside `frontend`:

```powershell
flutter pub get
flutter run -d chrome --web-port=54545 --dart-define=API_BASE_URL=http://localhost:8080
```

If the `web` folder is missing, first run `flutter create --platforms=web .` in `frontend`, then repeat the commands.

## 4. Try the administrator features

1. Open the Flutter application in Chrome on the **same computer**.
2. Open the application's Admin Login entry.
3. Sign in with `demo.superadmin@example.com` / `DemoAdmin2026!`.
4. Use the Super Admin dashboard to create institutions or add an Institution Admin tied to one of the sample institutions.
5. Sign out and sign in as that Institution Admin to create or edit announcements and events for the assigned institution.

An Institution Admin password is chosen when creating that account; no additional static institution-admin credentials are included.

## Already ran an older Arabic sample version? Reset the demo data

**Important: this permanently deletes the old Docker demo database, including any test accounts/edits you made there. It does NOT delete your original PostgreSQL database on port 5432.**

1. Stop the demo Spring Boot process with `Ctrl+C`. You can also stop Flutter and leave Docker Desktop running.
2. Open PowerShell in the **repository root** of this *new* version.
3. Run:

```powershell
docker compose -f docker-compose.demo.yml down -v
docker compose -f docker-compose.demo.yml up -d
```

4. Restart the backend using the commands in step 2, then refresh or restart Flutter. The sample records will now be in English and the fixed demo Super Admin account will be created.

If you don't reset the volume, existing Arabic records remain in PostgreSQL; replacing Java source files does not translate records already saved in the database.

## Safety and limitations

- Keep `SPRING_PROFILES_ACTIVE=demo` and the fixed admin credentials **away from production**. The demo API binds to localhost by default.
- The database password `demo_local_only` is a deliberate local test value from `docker-compose.demo.yml`, never a production password.
- The regular (non-demo) admin bootstrap still uses `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD` from environment variables and is **disabled** in demo mode.
- Images are intentionally omitted from sample seed records to avoid external copyrighted image files.
- Announcement/event timestamps are generated on their first insertion. If events become outdated, reset the demo volume.
- This is a local portfolio configuration. Compile and run it on your own Windows computer before sharing; automated end-to-end validation has not been completed in this environment.
