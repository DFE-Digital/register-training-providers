# 2. Tool Versioning Strategy

Date:\*\* 2025-07-01

## Status

Accepted

## Context

Solo development project currently using asdf for local version management. Need to establish consistent versioning approach as project grows and for CI/CD consistency.

## Decision

Use **asdf** with a `.tool-versions` file to standardize Node.js and Ruby versions across environments.

- Node.js and Ruby versions specified in project root `.tool-versions` file
- Replaces individual version files (`.ruby-version`, `.node-version`)
- CI/CD reads from same file for consistency
- Verification script checks local versions match requirements
- Docker images use explicitly pinned versions that should align with `.tool-versions` within a reasonable window\*

\*Note: Docker base images and Alpine packages may lag behind `.tool-versions` by days/weeks due to release cycles

## Alternatives Considered

- Docker dev environments (too complex)
- Manual documentation (error-prone)
- Individual version managers (multiple tools to manage)

## Consequences

**Positive:** Consistent environments, future-proofs for team growth, aligns with planned CI
**Negative:** Additional tooling dependency
**Neutral:** Formalizes existing asdf usage
