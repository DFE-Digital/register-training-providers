## 7. Seed Data Management

**Date:** 2026-02-09

## Status

**Accepted**

## Context

Seed data is accessible from `lib/data` for the years **2024**, **pre-2024**, and **fullset**. All datasets are anonymised and free from any personally identifiable information (PII). The primary sources include the Publish service, Register service, and market registration teams.

- **Environments**: **Production**, **Staging**, and **QA** environments are all seeded from the **2024** dataset. Importantly, there are no relationships or dependencies between these environments, meaning that the staging and QA datasets will not replicate the production data.

## Decision

- **Maintain Environmental Independence**: Each environment (production, staging, and QA) will remain entirely independent, with no shared data mechanisms required.

- **Ad Hoc Data Seeding Process**: An ad hoc process will be developed to generate exact copies of the production data for the **2025** dataset, ensuring all copies are free from PII.

## Consequences

- **Single Source of Truth Time Drift**: Production will act as the definitive source for all records, thus ensuring data integrity across services. Each environment will represent a version of this truth at a specific point in time.

- **Custom Seeding Process**: A tailored ad hoc approach is necessary for creating exact copies of the production data. This approach provides flexibility while adhering to privacy standards.

This structured method of seed data management enhances security and functionality in development and testing environments, as other services
