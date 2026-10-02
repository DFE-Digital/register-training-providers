require "ostruct"
require "dfe/wizard/documentation/formatters/mermaid_formatter"
require "dfe/wizard/documentation/formatters/graphviz_formatter"

namespace :wizard do
  namespace :docs do
    desc "Generate documentation for all wizards"
    task generate: :environment do
      output_dir = "docs/wizards"

      ProviderChanges::Registry.fields.each do |field|
        wizard_class = ProviderChanges::Registry.wizard_for(field)
        # rubocop:disable Style/OpenStructUse
        wizard = wizard_class.new(state_store: OpenStruct.new, provider: Provider.new)
        # rubocop:enable Style/OpenStructUse

        wizard.documentation.generate_all(output_dir)
        puts "Generated docs for #{wizard_class.name}"
      end
    end
  end
end
