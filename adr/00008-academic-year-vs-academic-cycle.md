## 7. Academic year vs academic cycle

**Date:** 2026-03-19

## Status

**Accepted**

## Context

The service previously used both **academic year** and **academic cycle** to represent the same concept.
In practice, the domain only recognises the concept of an academic year, represented either as 2024 or 2024–2025, and no separate concept of an academic cycle exists.

The term academic cycle is not used in the business domain and makes the model ambiguous, as it suggests a different concept even though the underlying data represents an academic year.

## Decision

We will standardise on the term **academic year**.
All references to **academic cycle** will be removed from the codebase, database schema, and API.

An academic year may be represented either by its starting year (2024) or by an explicit range (2024–2025). These representations are equivalent and refer to the same academic year.

## Consequences

- All tables, models, and fields using `academic_cycle` will be renamed to use `academic_year`.
- Existing data will be migrated without changing the underlying values.
- Future development must use **academic year** exclusively.
- This removes domain ambiguity and aligns the service terminology with real-world usage.
