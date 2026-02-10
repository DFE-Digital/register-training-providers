## 7. Seed Data Management

**Date:** 2026-02-09

## Status

**Accepted**

## Context

Seed data is accessible from `lib/data`, comprising three distinct datasets:

- **fullset**: Contains the entirety of the data for the academic years 2019 to 2026 as well as all the partnerships.
- **2024**: Contains accredited providers data for the academic years 2024 to 2026 inclusive of the full history of partnerships formed for the academic years 2019 to 2026. This includes training providers related to the accredited providers.
- **pre-2024**: Contains the reminder of the training providers and the partnerships for the academic years 2019 to 2026, they are the ones that was not present in **2024**.

The sum of **pre-2024** plus **2024** is equal to **fullset**, with some minor alignments with accredited providers and its' partnerships and training providers.

All datasets are free from any personally identifiable information (PII). The primary sources include the Publish teacher training courses service, Register trainee teachers service, and market registration teams.

- **Environments**: **Production**, **Staging**, and **QA** environments are all seeded from the **2024** dataset. Importantly, there are no relationships or dependencies between these environments, meaning that the **Staging** and **QA** datasets will not replicate the **Production** dataset.

## Decision

- **Maintain Environmental Independence**: Each environment (**Production**, **Staging**, and **QA**) will remain entirely independent, with no shared data mechanisms required.

- **Ad Hoc Data Seeding Process**: An ad hoc process will be developed to generate exact copies of the production data for the forthcoming academic year ie **2025** dataset, ensuring all copies are free from PII.

## Consequences

- **Single Source of Truth Time Drift**: Production will act as the definitive source for all records, thus ensuring data integrity across services. Each environment will represent a version of this truth at a specific point in time.

- **Custom Seeding Process**: A tailored ad hoc approach is necessary for creating exact copies of the production data. This approach provides flexibility while adhering to privacy standards.

This structured method of seed data management enhances security and functionality in development and testing environments, as other services
