if defined?(DatabaseConsistency) && Rails.env.development?

  module DatabaseConsistency
    module Checkers
      class ProviderRotpIdPresenceChecker < ColumnPresenceChecker
      private

        def weak_option?
          return false if provider_rotp_id_without_validation_context?

          super
        end

        def provider_rotp_id_without_validation_context?
          model.name == "Provider" &&
            attribute.to_s == "rotp_id" &&
            validators.all? do |validator|
              validator.options[:unless] == :without_rotp_id?
            end
        end
      end
    end
  end
end
