module ProviderNavigation
  class View < ApplicationComponent
    attr_reader :provider, :active_tab, :debug_mode

    def initialize(provider:, active_tab:, debug_mode: false)
      @provider = provider
      @active_tab = active_tab
      @debug_mode = debug_mode
      super()
    end

    def tabs
      [
        { name: "Provider details", path: provider_path(provider, path_options) },
        { name: "Accreditations", path: provider_accreditations_path(provider, path_options) },
        { name: "Addresses", path: provider_addresses_path(provider, path_options) },
        { name: "Contacts", path: provider_contacts_path(provider, path_options) },
        { name: "Activity log", path: provider_activity_path(provider, path_options) },
      ]
    end

    def navigation_items
      tabs.map do |tab|
        classes = ["app-secondary-navigation__item"]
        classes << "app-secondary-navigation__item--active" if tab[:name] == active_tab

        {
          name: tab[:name],
          path: tab[:path],
          classes: classes.join(" "),
          active: tab[:name] == active_tab,
          current_page: tab[:name] == active_tab ? "page" : nil
        }
      end
    end

    def path_options
      @path_options ||= debug_mode ? { debug: "true" } : {}
    end
  end
end
