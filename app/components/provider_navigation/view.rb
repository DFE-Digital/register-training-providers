module ProviderNavigation
  class View < ApplicationComponent
    attr_reader :provider, :active_tab

    def initialize(provider:, active_tab:)
      @provider = provider
      @active_tab = active_tab
      super()
    end

    def tabs
      [
        { name: "Provider details", path: provider_path(provider) },
        { name: "Accreditations", path: provider_accreditations_path(provider) },
        { name: "Addresses", path: provider_addresses_path(provider) },
        { name: "Contacts", path: provider_contacts_path(provider) },
        { name: "Activity log", path: provider_activity_path(provider) },
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
  end
end
