# Institution Platform

An institution-management application with a **Flutter** user interface and a **Java / Spring Boot** REST API backed by **PostgreSQL**.

This is a portfolio/development snapshot; it is **not a production-hardened deployment**.

> **Want to review the local demo?** Follow [DEMO_SETUP.md](DEMO_SETUP.md). It includes English fictional sample data and fixed **demo-only** Super Admin test credentials. No access to the author's private data is required.

## Features

- Browse and search institutions.
- Display institution information, announcements, upcoming events and image-based display content.
- Institution administrator tools for managing their institution's content.
- Super administrator tools for managing institutions and administrator accounts.
- Arabic/English interface support.

## Technology

- Frontend: Flutter / Dart, HTTP client, shared preferences.
- Backend: Java 21, Spring Boot, Spring Security, Spring Data JPA.
- Database: PostgreSQL.
- Authentication: HTTP Basic for the development version, BCrypt for stored password hashes.

## Repository layout

```text
backend/   Spring Boot Maven application
frontend/  Flutter project (Android and iOS scaffolding included)
```

## Development setup

**1. Create a local PostgreSQL database** named `institution_platform`. Existing users are not included in this repository.

**2. Set backend environment variables** before starting Spring Boot. For example, in a PowerShell session:

```powershell
$env:DB_PASSWORD = 'YOUR_LOCAL_POSTGRES_PASSWORD'
$env:DB_URL = 'jdbc:postgresql://localhost:5432/institution_platform'
$env:DB_USERNAME = 'postgres'
$env:CORS_ALLOWED_ORIGINS = 'http://localhost:54545,http://192.168.1.102:54545'
```

Change the LAN address above to your computer's actual current IP. Start the backend from Eclipse or inside the same PowerShell session from `backend/`:

```powershell
.\mvnw.cmd spring-boot:run
```

**3. Optional one-time super administrator creation.** On a fresh database only, configure `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD` before the first start. The bootstrap will create an account only when the email does not already exist and **will not overwrite existing accounts**. Remove these environment variables after initial setup. Never commit real credentials.

**4. Run the frontend** from `frontend/`:

```powershell
flutter pub get
flutter run -d emulator-5554
```

The default `API_BASE_URL` is `http://10.0.2.2:8080` for Android Emulator, which reaches the development computer. Override it when using Flutter Web or a real device:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 54545 --dart-define=API_BASE_URL=http://192.168.1.102:8080
```

For this web-server example, connect a phone to the same Wi-Fi and visit `http://COMPUTER_IP:54545` using the computer's current IP. Ensure the backend is reachable and `CORS_ALLOWED_ORIGINS` includes the frontend origin. The `--dart-define` value is **build configuration, not a secret vault**.

To add Flutter Web build files if your local Flutter SDK requires them, use `flutter create --platforms=web .` inside `frontend/`.

## Security notes

- Development uses HTTP Basic authentication; **do not expose it publicly over HTTP**. Production needs HTTPS and review of authentication/session management, CSRF/CORS and access controls.
- Database password is supplied through `DB_PASSWORD`; no database secrets are committed.
- For non-demo environments, initial super administrator password is supplied through `SUPER_ADMIN_PASSWORD`, only when needed. In demo mode, publicly documented fixed credentials exist **only for localhost demo testing**; never enable the demo profile on a real deployment.
- Keep real database exports, local configuration, tokens, keystores and user data out of Git.
- `spring.jpa.hibernate.ddl-auto=update` is for local development; use migrations and backups in production.
- CORS is configured with `CORS_ALLOWED_ORIGINS` and is not a substitute for authorization.
- Database schema retains some legacy table mappings for migration compatibility; see `backend/README_INSTITUTION_PLATFORM.md`.

## Verification

This snapshot was reviewed for obvious embedded credentials and generated build files. Compilation/runtime tests are **not included** here; run Maven tests and `flutter analyze` on a development machine before publishing.
