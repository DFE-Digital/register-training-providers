# 2. Tool Versioning Strategy

Date: 2025-07-01

## Status

Accepted

## Context

Multiple tools were being used to manage versions of Node.js and Ruby across development and CI/CD environments. Individual version files (`.ruby-version`, `.node-version`) and ad hoc tooling configurations created inconsistencies and increased maintenance overhead as the project evolved.

## Decision

Use **asdf** with a `.tool-versions` file to standardize Node.js and Ruby versions across all environments.

## Rationale

Adopting a single source of truth for tool versions simplifies development workflows and reduces the risk of inconsistencies. This approach provides:

- **Unified version specification:** Node.js and Ruby versions are defined in a single `.tool-versions` file located in the project root.
- **Replacement of individual version files:** Existing `.ruby-version` and `.node-version` files are replaced to eliminate duplication and confusion.
- **CI/CD consistency:** Build pipelines read versions directly from `.tool-versions` to ensure uniform environments across development and deployment.
- **Automated verification:** A script validates that local tool versions align with the specified requirements.
- **Docker version alignment:** Docker images use explicitly pinned Node.js and Ruby versions intended to align with `.tool-versions` within a reasonable window.\*

\*Note: Due to release cycles, Docker base images and Alpine packages may lag behind `.tool-versions` by several days or weeks.

Alternatives such as Docker-based development environments were considered but rejected due to added complexity. Manual documentation of tool versions was determined to be error-prone. Relying on multiple individual version managers introduced unnecessary tooling overhead.

## Consequences

- **Positive:**

  - Provides consistent environments across development and CI/CD.
  - Facilitates future team growth by standardizing tooling.
  - Aligns with planned automation and deployment practices.

- **Negative:**

  - Introduces an additional dependency on asdf for version management.

- **Neutral:**

  - Formalizes existing asdf usage and consolidates version configuration.
