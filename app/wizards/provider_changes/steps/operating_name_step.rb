module ProviderChanges
  module Steps
    class OperatingNameStep
      include DfE::Wizard::Step
      include ActiveModel::Validations::Callbacks

      attribute :operating_name

      validates :operating_name, presence: true

      validate :operating_name_changed, unless: -> { errors.key?(:operating_name) }

      def self.permitted_params
        %i[operating_name]
      end

    private

      def operating_name_changed
        errors.add(:operating_name, :same) if wizard.provider.operating_name == operating_name
      end
    end
  end
end
