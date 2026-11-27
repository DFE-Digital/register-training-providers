module ProviderChanges
  module Steps
    class StatusStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      Status = Struct.new(:value, :label)

      attribute :new_status

      validate :new_status_transitionable, unless: -> { errors.key?(:new_status) }

      def self.permitted_params
        %i[new_status]
      end

      def statuses
        wizard.provider.allowed_status_transitions.map do |status|
          Status.new(
            status.to_s,
            I18n.t("providers.statuses.#{status}")
          )
        end
      end

    private

      def new_status_transitionable
        if new_status.blank?
          errors.add(:new_status, :blank)

          return
        end

        errors.add(:new_status, :inclusion) unless wizard.provider.transitionable_status?(new_status)
      end
    end
  end
end
