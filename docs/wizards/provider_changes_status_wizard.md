# Wizard Documentation

**Structure Type:** `graph`
**Generated:** 2026-10-26T10:32:50Z
**Processor:** DfE::Wizard::StepsProcessor

## Overview

| Metric                           | Value |
| -------------------------------- | ----- |
| Total Steps                      | 4     |
| Simple Transitions               | 2     |
| Conditional Transitions          | 1     |
| Multiple Conditional Transitions | 0     |
| Custom Branching Transitions     | 0     |
| **Total Transitions**            | **3** |

## Root Entry Point (Fixed)

**Entry Point:** `new_status`

All users start at this step. No conditional logic applies.

## Wizard Flow

```
[:new_status]
├─→ [:reasons] reason_capture_required? (✓)
│   ↓
│ [:effective_date]
│   ↓
│ [:check_your_answers]
└─→ [:effective_date] reason_capture_required? (✗)
```

### Legend

- **━━** Simple edge (linear progression, no condition)
- **─┬─** Conditional edge (if/else decision point)
- **┼** Multiple conditional edge (N-way branching)
- **⊕** Custom branching edge (complex status-driven routing)

## Steps Inventory

| Step ID              | Label              | Class                                             |
| -------------------- | ------------------ | ------------------------------------------------- |
| `new_status`         | New Status         | `ProviderChanges::Steps::StatusStep`              |
| `reasons`            | Reasons            | `ProviderChanges::Steps::ReasonsStep`             |
| `effective_date`     | Effective Date     | `ProviderChanges::Steps::StatusEffectiveDateStep` |
| `check_your_answers` | Check Your Answers | `ProviderChanges::Steps::CheckYourAnswersStep`    |

## Detailed Step Specifications

### Step: `new_status`

**Label:** New Status
**Class:** `ProviderChanges::Steps::StatusStep`
**Entry Point:** ✓ Yes
**Exit Points:** `effective_date`, `reasons`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute    | Type                       | Required | Description |
| ------------ | -------------------------- | :------: | ----------- |
| `new_status` | `ActiveModel::Type::Value` |    ✗     |             |

#### Operations

| Operation  | Description        |
| ---------- | ------------------ |
| `validate` | Validate operation |
| `persist`  | Persist operation  |

### Step: `reasons`

**Label:** Reasons
**Class:** `ProviderChanges::Steps::ReasonsStep`
**Entry Point:** ✗ No
**Exit Points:** `effective_date`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute      | Type                        | Required | Description |
| -------------- | --------------------------- | :------: | ----------- |
| `reasons`      | `ActiveModel::Type::Value`  |    ✗     |             |
| `other_reason` | `ActiveModel::Type::String` |    ✗     |             |

#### Validations

- **other_reason** (`length`):

#### Operations

| Operation  | Description        |
| ---------- | ------------------ |
| `validate` | Validate operation |
| `persist`  | Persist operation  |

### Step: `effective_date`

**Label:** Effective Date
**Class:** `ProviderChanges::Steps::StatusEffectiveDateStep`
**Entry Point:** ✗ No
**Exit Points:** `check_your_answers`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute            | Type                         | Required | Description |
| -------------------- | ---------------------------- | :------: | ----------- |
| `effective_on_day`   | `ActiveModel::Type::Integer` |    ✗     |             |
| `effective_on_month` | `ActiveModel::Type::Integer` |    ✗     |             |
| `effective_on_year`  | `ActiveModel::Type::Integer` |    ✗     |             |
| `effective_on`       | `ActiveModel::Type::Date`    |    ✗     |             |

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

This wizard contains **3 transitions** across 4 types:

- **2 simple transitions** – Linear progression (unconditional)
- **1 conditional transitions** – If/else branching logic
- **0 multiple conditional transitions** – N-way branching
- **0 custom branching transitions** – Complex status-driven routing

### Simple Transitions

Simple transitions allow linear, unconditional progression from one step to the next.

| From             | To                   | Behavior                       |
| ---------------- | -------------------- | ------------------------------ |
| `reasons`        | `effective_date`     | Always proceeds (no condition) |
| `effective_date` | `check_your_answers` | Always proceeds (no condition) |

### Conditional Transitions (If/Else)

Conditional transitions split the flow into two branches based on a predicate evaluation.

#### `new_status` → `reasons` OR `effective_date`

| Property        | Value                      |
| --------------- | -------------------------- |
| From            | `new_status`               |
| Condition       | `reason_capture_required?` |
| Then (if true)  | `reasons`                  |
| Else (if false) | `effective_date`           |

**Flow Logic:**

Evaluates the predicate `reason_capture_required?`:

- If condition is **true** → proceed to `reasons`
- If condition is **false** → proceed to `effective_date`

## Wizard Statistics

| Metric                           | Count |
| -------------------------------- | ----- |
| Total Steps                      | 4     |
| Simple Transitions               | 2     |
| Conditional Transitions          | 1     |
| Multiple Conditional Transitions | 0     |
| Custom Branching Transitions     | 0     |
| **Total Transitions**            | **3** |

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
  :root_step: "new_status",
  :steps: {
    :new_status: {
      :class: "ProviderChanges::Steps::StatusStep",
      :label: "New Status",
      :attributes: [
        {
          :name: "new_status",
          :type: "ActiveModel::Type::Value"
        }
      ],
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
    },
    :reasons: {
      :class: "ProviderChanges::Steps::ReasonsStep",
      :label: "Reasons",
      :attributes: [
        {
          :name: "reasons",
          :type: "ActiveModel::Type::Value"
        },
        {
          :name: "other_reason",
          :type: "ActiveModel::Type::String"
        }
      ],
      :validators: [
        {
          :name: "other_reason",
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
    :effective_date: {
      :class: "ProviderChanges::Steps::StatusEffectiveDateStep",
      :label: "Effective Date",
      :attributes: [
        {
          :name: "effective_on_day",
          :type: "ActiveModel::Type::Integer"
        },
        {
          :name: "effective_on_month",
          :type: "ActiveModel::Type::Integer"
        },
        {
          :name: "effective_on_year",
          :type: "ActiveModel::Type::Integer"
        },
        {
          :name: "effective_on",
          :type: "ActiveModel::Type::Date"
        }
      ],
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
      :from: "reasons",
      :to: "effective_date",
      :type: "simple",
      :label: null
    },
    {
      :from: "effective_date",
      :to: "check_your_answers",
      :type: "simple",
      :label: null
    },
    {
      :from: "new_status",
      :when: {},
      :then: "reasons",
      :else: "effective_date",
      :type: "conditional",
      :label: "reason_capture_required?"
    }
  ],
  :counts: {
    :steps: 4,
    :simple_transitions: 2,
    :conditional_transitions: 1,
    :multiple_conditional_transitions: 0,
    :custom_branching_transitions: 0
  },
  :wizard_name: "Provider changes/status wizard"
}
```

**Note:** This is the unified metadata format consumed by all documentation formatters.
