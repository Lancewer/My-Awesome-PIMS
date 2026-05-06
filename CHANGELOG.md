# Changelog

All notable changes to MyNote will be documented in this file.

## [1.0.0.0] - 2026-05-06

### Added
- FastAPI backend with full CRUD for notes (create, read, update, soft-delete)
- Hierarchical tag system supporting up to 3 levels (`#parent/child/grandchild`)
- Full-text search across note content
- Tag listing with note counts
- Alembic migration system for database schema management
- Docker Compose setup with PostgreSQL and auto-migration on startup
- 35 TDD tests covering repository, service, and API layers (93% coverage)
