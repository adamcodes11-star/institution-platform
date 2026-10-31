# Institution Platform Backend

This Spring Boot backend powers the generic institutions platform.

## Main application

Run `com.institutionplatform.InstitutionPlatformApplication` as a Java application.

## Main APIs

- `GET /api/institutions`
- `GET /api/announcements/institution/{id}/active`
- `GET /api/announcements/institution/{id}/display`
- `GET /api/events/institution/{id}/upcoming`
- `GET /api/auth/me`

Institution administrators can manage their announcements and events after
HTTP Basic authentication. Super administrators can manage institutions and
institution administrator accounts.

## Existing database data

The entity names and API have changed to institutions, but the existing
`mosques`, `mosque_id`, `village`, and `show_on_mosque_screen` database names
are intentionally retained as compatibility mappings. This prevents Hibernate
from creating disconnected replacement tables or losing the existing records.

`spring.jpa.hibernate.ddl-auto=update` adds the new institution and event
columns/tables when the application starts.
