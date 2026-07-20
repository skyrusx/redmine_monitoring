# Changelog

## 0.2.2

- Added `MonitoringErrors::HealthStatus`.
- Added dashboard health/status block.
- Added table counts and latest record status for monitoring entities.
- Added email/Telegram notification diagnostics.
- Updated README with operational health information.

## 0.2.1

- Adapted the plugin for Redmine 4.2.

## 0.2.0

- Added sensitive data masking for params and headers.
- Added size limits for params, headers, env, and backtrace.
- Added settings to disable headers/env persistence.
- Added separate retention for recommendations and security scans.
- Applied `security_keep_html` while importing Brakeman reports.
- Added audit-friendly documentation for stored monitoring data.

## 0.1.5

- Added regression tests for plugin boot without Bullet, filters, retention, security reports, and notification dispatching.
- Added a production-like Bullet integration smoke test.
- Added migration compatibility checks for PostgreSQL/MySQL-sensitive constructs.
- Replaced PostgreSQL-only `jsonb` migration columns with adapter-portable `json` columns.
- Removed JSON column database defaults that are incompatible with MySQL.
- Reworked security warning scopes to avoid PostgreSQL-only regex and JSON functions on MySQL.
- Fixed metrics settings fallback lookup.
- Removed local IDE/macOS artifacts from the working tree.

## 0.1.4

- Fixed plugin boot in environments without Bullet.
- Fixed security report presence check.
- Fixed `enabled_formats` validation.
- Removed project-specific email recipient domain filtering.
- Updated README with current features and settings.
