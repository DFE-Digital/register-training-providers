# Wizard Documentation

**Structure Type:** `graph`
**Generated:** 2026-09-02T11:40:22Z
**Processor:** DfE::Wizard::StepsProcessor

## Overview

| Metric                           | Value |
| -------------------------------- | ----- |
| Total Steps                      | 3     |
| Simple Transitions               | 0     |
| Conditional Transitions          | 0     |
| Multiple Conditional Transitions | 0     |
| Custom Branching Transitions     | 0     |
| **Total Transitions**            | **0** |

## Root Entry Point (Fixed)

**Entry Point:** `effective_academic_year`

All users start at this step. No conditional logic applies.

## Wizard Flow

```
[:effective_academic_year]
  ↓
[:provider_code]
  ↓
[:check_your_answers]
```

### Legend

- **━━** Simple edge (linear progression, no condition)
- **─┬─** Conditional edge (if/else decision point)
- **┼** Multiple conditional edge (N-way branching)
- **⊕** Custom branching edge (complex status-driven routing)

## Steps Inventory

| Step ID                   | Label                   | Class                                               |
| ------------------------- | ----------------------- | --------------------------------------------------- |
| `effective_academic_year` | Effective Academic Year | `ProviderChanges::Steps::EffectiveAcademicYearStep` |
| `provider_code`           | Provider Code           | `ProviderChanges::Steps::CodeStep`                  |
| `check_your_answers`      | Check Your Answers      | `ProviderChanges::Steps::CheckYourAnswersStep`      |

## Detailed Step Specifications

### Step: `effective_academic_year`

**Label:** Effective Academic Year
**Class:** `ProviderChanges::Steps::EffectiveAcademicYearStep`
**Entry Point:** ✓ Yes
**Exit Points:** `provider_code`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute      | Type                      | Required | Description |
| -------------- | ------------------------- | :------: | ----------- |
| `effective_on` | `ActiveModel::Type::Date` |    ✗     |             |

#### Validations

- **effective_on** (`presence`):

#### Operations

| Operation  | Description        |
| ---------- | ------------------ |
| `validate` | Validate operation |
| `persist`  | Persist operation  |

### Step: `provider_code`

**Label:** Provider Code
**Class:** `ProviderChanges::Steps::CodeStep`
**Entry Point:** ✗ No
**Exit Points:** `check_your_answers`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute | Type                       | Required | Description |
| --------- | -------------------------- | :------: | ----------- |
| `code`    | `ActiveModel::Type::Value` |    ✗     |             |

#### Validations

- **code** (`presence`):
- **code** (`format`):
- **code** (`length`):

#### Operations

| Operation  | Description        |
| ---------- | ------------------ |
| `validate` | Validate operation |
| `persist`  | Persist operation  |

### Step: `check_your_answers`

**Label:** Check Your Answers
**Class:** `ProviderChanges::Steps::CheckYourAnswersStep`
**Entry Point:** ✗ No
**Exit Points:** [Wizard End]

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Operations

| Operation  | Description        |
| ---------- | ------------------ |
| `validate` | Validate operation |
| `persist`  | Persist operation  |

## Transitions Reference

This wizard contains **2 transitions** across 4 types:

- **2 simple transitions** – Linear progression (unconditional)
- **0 conditional transitions** – If/else branching logic
- **0 multiple conditional transitions** – N-way branching
- **0 custom branching transitions** – Complex status-driven routing

### Simple Transitions

Simple transitions allow linear, unconditional progression from one step to the next.

| From                      | To                   | Behavior                       |
| ------------------------- | -------------------- | ------------------------------ |
| `effective_academic_year` | `provider_code`      | Always proceeds (no condition) |
| `provider_code`           | `check_your_answers` | Always proceeds (no condition) |

## Wizard Statistics

| Metric                           | Count |
| -------------------------------- | ----- |
| Total Steps                      | 3     |
| Simple Transitions               | 0     |
| Conditional Transitions          | 0     |
| Multiple Conditional Transitions | 0     |
| Custom Branching Transitions     | 0     |
| **Total Transitions**            | **2** |

## Example User Journeys

### Journey 1: Typical Path

```
1. [Entry]  Entry Step
2. [Linear] Step A
3. [Cond]   Step B or C (conditional)
4. [N-way]  Step D (branching)
5. [Exit]   Terminal Step
```

### Journey 2: Alternative Path

```
1. [Entry]  Entry Step (alternate)
2. [Linear] Step A
3. [Status] Different terminal step based on status
```

**Note:** Actual journeys depend on wizard state transitions and predicates.

## Raw Metadata

```json
{
  :structure_type: "graph",
  :root_step: "effective_academic_year",
  :steps: {
    :effective_academic_year: {
      :class: "ProviderChanges::Steps::EffectiveAcademicYearStep",
      :label: "Effective Academic Year",
      :attributes: [
        {
          :name: "effective_on",
          :type: "ActiveModel::Type::Date"
        }
      ],
      :validators: [
        {
          :name: "effective_on",
          :class: "ActiveModel::Validations::PresenceValidator",
          :type: "presence",
          :message: null
        }
      ],
      :operations: [
        {
          :name: "validate",
          :description: "Validate operation"
        },
        {
          :name: "persist",
          :description: "Persist operation"
        }
      ]
    },
    :provider_code: {
      :class: "ProviderChanges::Steps::CodeStep",
      :label: "Provider Code",
      :attributes: [
        {
          :name: "code",
          :type: "ActiveModel::Type::Value"
        }
      ],
      :validators: [
        {
          :name: "code",
          :class: "ActiveModel::Validations::PresenceValidator",
          :type: "presence",
          :message: null
        },
        {
          :name: "code",
          :class: "ActiveModel::Validations::FormatValidator",
          :type: "format",
          :message: null
        },
        {
          :name: "code",
          :class: "ActiveModel::Validations::LengthValidator",
          :type: "length",
          :message: null
        }
      ],
      :operations: [
        {
          :name: "validate",
          :description: "Validate operation"
        },
        {
          :name: "persist",
          :description: "Persist operation"
        }
      ]
    },
    :check_your_answers: {
      :class: "ProviderChanges::Steps::CheckYourAnswersStep",
      :label: "Check Your Answers",
      :attributes: [],
      :validators: [],
      :operations: [
        {
          :name: "validate",
          :description: "Validate operation"
        },
        {
          :name: "persist",
          :description: "Persist operation"
        }
      ]
    }
  },
  :transitions: [
    {
      :from: "effective_academic_year",
      :to: "provider_code",
      :type: "simple",
      :label: null
    },
    {
      :from: "provider_code",
      :to: "check_your_answers",
      :type: "simple",
      :label: null
    }
  ],
  :counts: {
    :steps: 3,
    :simple_edges: 2,
    :conditional_edges: 0,
    :multiple_conditional_edges: 0,
    :custom_branching_edges: 0
  },
  :wizard_name: "Provider changes/code wizard"
}
```

**Note:** This is the unified metadata format consumed by all documentation formatters.
