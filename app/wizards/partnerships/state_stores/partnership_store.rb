module Partnerships
  module StateStores
    class PartnershipStore
      include DfE::Wizard::StateStore

      def has_end_date?
        read.with_indifferent_access[:has_end_date].to_s == "true"
      end
    end
  end
end
