module AddressJourney
  class SelectPresenter < BasePresenter
    include AddressJourney::Shared::SelectPresenterBehavior

    attr_reader :results, :find_form, :error

    def initialize(results:, find_form:, provider:, error: nil)
      super(provider:)
      @results = results
      @find_form = find_form
      @error = error
    end

    def form_url
      provider_select_path(provider)
    end

    def back_path
      provider_new_find_path(provider)
    end

    def change_search_path
      provider_new_find_path(provider)
    end
  end
end
