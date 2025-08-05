# 4. Hybrid UUID and integer ID strategy

Date: 2025-08-05

## Status

Accepted

## Context

Currently, our service uses sequential integer IDs as primary keys. While this is standard and efficient for internal use, exposing these IDs externally (such as in URLs or a future API) would create predictable and enumerable identifiers, which increases the risk of data exposure and unauthorized access — for example, via [IDOR (Insecure Direct Object Reference) attacks](https://owasp.org/www-community/attacks/Indirect_Object_Reference_Map).

Although we don’t yet have a public API, planning ahead allows us to adopt safer practices from the start without disruptive future migrations.

## Decision

We will adopt a **hybrid strategy** for identifiers:

- **Retain integer primary keys** for internal use, joins, and performance.
- **Introduce UUIDs** to key models (e.g., `User`, `Provider`, etc.).
- UUIDs will be used for external references, including:
  - Future API endpoints.
  - Route parameters (e.g., `UsersController#show` will look up by `uuid`).
  - Public-facing identifiers in links or logs.

- Models will override `to_param` to return the UUID.
- UUIDs will be generated automatically and stored in a `uuid` column.
- UUIDs will not replace the primary key but will be indexed and enforced for uniqueness.

## Rationale

### Why keep integer IDs?

- Simpler for internal references and debugging.
- Maintains compatibility with existing database conventions.
- Offers performance benefits for joins and foreign keys.

### Why add UUIDs?

- Prevents resource enumeration when exposed externally.
- Encourages clean separation between internal and external identifiers.
- Aligns with secure-by-default principles early in development.
- Allows future API design to be safer from the start.

## Consequences

### Benefits

- Improves future security posture without disrupting internal logic.
- Offers flexibility for both human-friendly internal workflows and secure external use.
- Keeps database migrations minimal and reversible at this early stage.

### Trade-offs

- Slightly more complexity in model and route setup.
- Developers must be consistent about which identifier to use (internal `id` vs external `uuid`).
- Adds additional database indexes and validations to manage.
