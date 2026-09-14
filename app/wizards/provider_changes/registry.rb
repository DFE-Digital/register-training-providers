module ProviderChanges
  # Maps each provider change field to the wizard, state store and review
  # presenter that handle it.
  class Registry
    FIELDS = {
      "code" => { wizard: CodeWizard,
                  state_store: StateStores::CodeStore,
                  review: Presenters::CodeReview },
      "ukprn" => { wizard: UkprnWizard,
                   state_store: StateStores::UkprnStore,
                   review: Presenters::UkprnReview },
      "urn" => { wizard: UrnWizard,
                 state_store: StateStores::UrnStore,
                 review: Presenters::UrnReview }
    }.freeze

    def self.fields
      FIELDS.keys
    end

    def self.registered?(field)
      FIELDS.key?(field.to_s)
    end

    def self.wizard_for(field)
      FIELDS.fetch(field.to_s).fetch(:wizard)
    end

    def self.state_store_for(field)
      FIELDS.fetch(field.to_s).fetch(:state_store)
    end

    def self.review_for(field)
      FIELDS.fetch(field.to_s).fetch(:review)
    end
  end
end
