# Wizard Documentation

**Structure Type:** `graph`
**Generated:** 2026-09-14T12:32:54Z
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

**Entry Point:** `effective_date`

All users start at this step. No conditional logic applies.

## Wizard Flow

```
[:effective_date]
  ↓
[:new_legal_name]
  ↓
[:check_your_answers]
```

### Legend

- **━━** Simple edge (linear progression, no condition)
- **─┬─** Conditional edge (if/else decision point)
- **┼** Multiple conditional edge (N-way branching)
- **⊕** Custom branching edge (complex status-driven routing)

## Steps Inventory

| Step ID              | Label              | Class                                          |
| -------------------- | ------------------ | ---------------------------------------------- |
| `effective_date`     | Effective Date     | `ProviderChanges::Steps::EffectiveDateStep`    |
| `new_legal_name`     | New Legal Name     | `ProviderChanges::Steps::LegalNameStep`        |
| `check_your_answers` | Check Your Answers | `ProviderChanges::Steps::CheckYourAnswersStep` |

## Detailed Step Specifications

### Step: `effective_date`

**Label:** Effective Date
**Class:** `ProviderChanges::Steps::EffectiveDateStep`
**Entry Point:** ✓ Yes
**Exit Points:** `new_legal_name`

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

### Step: `new_legal_name`

**Label:** New Legal Name
**Class:** `ProviderChanges::Steps::LegalNameStep`
**Entry Point:** ✗ No
**Exit Points:** `check_your_answers`

#### Description

Placeholder for step description. Add contextual information about
this step's purpose, user interactions, and business logic.

#### Attributes

| Attribute    | Type                       | Required | Description |
| ------------ | -------------------------- | :------: | ----------- |
| `legal_name` | `ActiveModel::Type::Value` |    ✗     |             |

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

| From             | To                   | Behavior                       |
| ---------------- | -------------------- | ------------------------------ |
| `effective_date` | `new_legal_name`     | Always proceeds (no condition) |
| `new_legal_name` | `check_your_answers` | Always proceeds (no condition) |

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
  :root_step: "effective_date",
  :steps: {
    :effective_date: {
      :class: "ProviderChanges::Steps::EffectiveDateStep",
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
    :new_legal_name: {
      :class: "ProviderChanges::Steps::LegalNameStep",
      :label: "New Legal Name",
      :attributes: [
        {
          :name: "legal_name",
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
      :from: "effective_date",
      :to: "new_legal_name",
      :type: "simple",
      :label: null
    },
    {
      :from: "new_legal_name",
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
  :wizard_name: "Provider changes/legal name wizard"
}
```

**Note:** This is the unified metadata format consumed by all documentation formatters.
