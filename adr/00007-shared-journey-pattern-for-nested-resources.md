# 7. Shared Journey Pattern for Nested Resources

**Date:** 2025-11-04

## Status

Accepted

## Context

Rails applications typically manage resources in a RESTful manner, but many government services require multi-page journeys for building resources. Additionally, some nested resources can be added both as part of their parent's creation journey and as standalone resources for existing parents.

For example, provider addresses can be:

1. Added during provider creation (as part of the provider setup journey)
2. Managed independently for existing providers (as a nested resource)

This creates a challenge: how to share functionality between two parallel journeys while maintaining clean, DRY code and sensible routes.

## Decision

We implement a **shared journey pattern** that uses:

### Architecture Components

1. **Controller Concerns** - Extract shared controller logic into concerns (`AddressFinder`, `AddressSelector`, `AddressFormHandler`)
2. **Shared Views** - Consolidate identical views into shared partials in `app/views/{resource}_journey/`
3. **Shared Presenter Modules** - Extract common presenter logic into shared modules (e.g., `AddressJourney::Shared::SelectPresenterBehavior`)
4. **Context-Specific Presenters** - Presenters that implement only the context-specific path generation
5. **Separate Controllers** - Each journey has its own controller classes, but they share concerns

### Route Structure

**Setup Journey** (namespace-based):

```ruby
namespace :providers do
  namespace :setup, path: "new" do
    namespace :addresses do
      # Creates /providers/new/addresses/* routes
      # Route helpers: providers_setup_addresses_*
    end
  end
end
```

**Management Journey** (nested resource-based):

```ruby
resources :providers do
  # Manual routes for multi-step flows
  get "addresses/find/new", to: "providers/addresses/find#new", as: :new_find
  post "addresses/find", to: "providers/addresses/find#create", as: :find
  # Route helpers: provider_*
end
```

### Key Pattern Elements

- **Controller Concerns**: Define interfaces requiring 5-7 methods to be implemented by controllers
- **Temporary Storage**: Use purpose strings to distinguish contexts (e.g., `:find_address_#{provider.id}` vs `:find_address_create_provider`)
- **Presenter Polymorphism**: Shared behavior modules with context-specific path generation
- **View Consolidation**: Single source of truth for view templates

## Consequences

### Benefits

- **DRY**: Shared logic in concerns and presenters eliminates duplication
- **Consistency**: Shared views ensure UI consistency across journeys
- **Flexibility**: Context-specific paths and behaviors where needed
- **Maintainability**: Single source of truth for shared logic
- **Scalability**: Pattern can be extended to other nested resources

### Trade-offs

- **Complexity**: Additional abstraction layer requires understanding of the pattern
- **Route Naming**: Different conventions for setup vs management (namespace-based vs nested resource-based)
- **Context Awareness**: Presenters and controllers must be context-aware
- **Learning Curve**: New developers need to understand the pattern before extending it

### Implementation Details

#### Controller Concerns Interface

Each concern requires implementing specific methods:

**AddressFinder** requires:

- `find_purpose` - Purpose string for temporary storage
- `search_results_purpose` - Purpose string for search results
- `select_path` - Redirect path after successful search
- `build_find_presenter(form)` - Presenter factory
- `provider` - Provider instance (varies by context)

**AddressSelector** requires:

- `find_purpose`, `search_results_purpose`
- `find_path` - Redirect path if search results missing
- `confirm_path` - Redirect path after selection
- `setup_address_form(address_form)` - Optional, defaults to setting provider_id
- `save_selected_address(address_form)` - Save selected address
- `build_select_presenter(results, find_form, error)` - Presenter factory
- `provider` - Provider instance

**AddressFormHandler** requires:

- `address_purpose` - Purpose string for temporary storage
- `address_success_path` - Redirect path after successful save
- `build_address_presenter(form, context, address = nil)` - Presenter factory
- `context_for_form` - Context symbol (:new or :edit)
- `setup_address_form_mode` - Optional, defaults to no-op
- `provider` - Provider instance

#### Route Naming Conventions

**Setup routes**: Use `providers_setup_addresses_*` prefix (plural "providers" due to namespace)

**Management routes**: Use `provider_*` prefix (singular "provider" due to nested resource)

**Route Helper Patterns**:

1. GET routes with "/new": Use `provider_new_*` prefix (e.g., `provider_new_find_path`)
2. POST routes without "/new": Use `provider_*` prefix (e.g., `provider_find_path`)
3. Routes with ID: Require both resource and `provider_id:` parameter (e.g., `provider_address_path(address, provider_id: provider.id)`)

#### View Consolidation

Views are consolidated into shared partials:

- `app/views/address_journey/_find_form.html.erb` - Postcode search form
- `app/views/address_journey/_select_form.html.erb` - Address selection form
- `app/views/address_journey/_manual_entry_form.html.erb` - Manual address entry form
- `app/views/address_journey/_check_form.html.erb` - Check your answers form

Both journey views render these shared partials, ensuring consistency.

#### Key Differences Between Journeys

**Provider Loading**:

- Management: `Provider.find(params[:provider_id])` - ActiveRecord lookup
- Setup: `current_user.load_temporary(Provider, purpose: :create_provider)` - Temporary storage

**Success Paths**:

- Management: `provider_addresses_path(provider)` - Index page
- Setup: `journey_service.next_path` - Next step in provider creation

**Purpose Strings**:

- Management: Provider-specific (e.g., `:"find_address_#{provider.id}"`)
- Setup: Journey-specific (e.g., `:find_address_create_provider`)

## Extending the Pattern

To add a new nested resource journey:

1. **Create Concerns**: Extract shared controller logic into concerns
2. **Create Forms**: Form objects for each step
3. **Create Presenters**: Context-specific presenters with shared behavior modules
4. **Create Views**: Shared partials in `app/views/{resource}_journey/`
5. **Define Routes**: Use appropriate namespace or nested resource structure
6. **Implement Controllers**: Include concerns and implement required methods
