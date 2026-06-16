## 9. API access deadman switch

**Date:** 2026-06-15

## Status

**Accepted**

## Context

In case of a dangerous number of requests, or possible attacks, to the API, there needs to be a method of entirely disabling API access within control of the team.

## Decision

- Create a githib workflow to enable and disable access to the API in each environment

## Consequences

- A github workflow has been created to control API access in all environments
