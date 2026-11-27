module Partnerships
  module Steps
    class FindPartnerStep
      include DfE::Wizard::Step

      attribute :partner_id, :string

      validate :partner_id_present
      validate :partner_must_exist, if: -> { partner_id.present? }

      def self.permitted_params
        %i[partner_id]
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Find")
      end

      def self.i18n_scope
        :activerecord
      end

    private

      def partner_id_present
        return if partner_id.present?

        errors.add(:partner_id, wizard.provider.accredited? ? :blank_training_partner : :blank_accredited_provider)
      end

      def partner_must_exist
        errors.add(:partner_id, :invalid) unless wizard.eligible_partners.exists?(partner_id)
      end
    end
  end
end
