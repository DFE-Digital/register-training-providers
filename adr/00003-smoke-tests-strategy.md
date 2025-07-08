# 3. Smoke Test Strategy

Date: 2025-07-01

## Status

Accepted

## Context

A proposal was considered to add smoke tests as an additional testing component. The objective was to provide a fast verification layer after deployment to detect major failures early.

## Decision

Do **not** introduce smoke tests as a separate testing component.

## Rationale

After evaluating the current testing strategy, it was determined that adding smoke tests would be redundant and provide no additional value. The application already includes:

- **Comprehensive unit tests** covering individual components and functionality.
- **Integration tests** verifying interactions between components.
- **Feature tests** simulating user interactions and validating application behaviour.
- **Monitoring** continuously assessing application health and performance.
- **Health endpoint** providing a simple, efficient method to verify application health.

Additional considerations include:

- **Avoidance of test redundancy:** Smoke tests frequently overlap with existing tests, causing duplicated effort without proportional benefit.
- **Faster feedback loops:** Focusing on existing comprehensive tests and monitoring maintains an efficient testing pipeline and reduces overall test runtime.
- **Maintenance overhead:** Introducing an additional testing layer increases complexity and resource requirements for upkeep.
- **Alignment with industry practices:** Modern development workflows emphasize end-to-end feature tests and monitoring over traditional smoke tests.
- **Risk mitigation through monitoring:** Real-time monitoring and health checks provide faster detection and alerting on critical issues compared to smoke tests.
- **Future scalability:** Planned load testing will stress-test the system at scale, identifying performance regressions that smoke tests are not designed to detect.
- **Cost-benefit consideration:** The investment required to build and maintain smoke tests outweighs the marginal benefits given existing coverage and monitoring.

## Consequences

- **Positive:**
  - Maintains simplicity and clarity in the testing strategy.
  - Allocates resources toward higher-value testing and monitoring activities.
  - Encourages reliance on proactive monitoring and alerting, improving operational readiness.

- **Negative:**
  - Potential initial risk exists if certain integration issues are detectable only in early smoke testing stages; this risk is mitigated by comprehensive integration and feature tests.

- **Neutral:**
  - Testing and deployment pipelines remain aligned with agile and continuous delivery practices.

Prioritizing load testing as a future initiative ensures the application remains robust and scalable, making smoke tests increasingly unnecessary.
