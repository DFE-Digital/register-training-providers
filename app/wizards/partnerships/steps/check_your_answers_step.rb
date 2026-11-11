module Partnerships
  module Steps
    class CheckYourAnswersStep
      include DfE::Wizard::Step

      def self.permitted_params
        []
      end
    end
  end
end
