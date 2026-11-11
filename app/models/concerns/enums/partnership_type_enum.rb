module PartnershipTypeEnum
  extend ActiveSupport::Concern

  PARTNERSHIP_TYPES = {
    recruitment: "recruitment",
    training_and_delivery: "training_and_delivery",
    student_fee_management: "student_fee_management",
    academic_award_making: "academic_award_making",
    placement: "placement"
  }.freeze

  RECRUITMENT = PARTNERSHIP_TYPES[:recruitment]
  TRAINING_AND_DELIVERY = PARTNERSHIP_TYPES[:training_and_delivery]
  STUDENT_FEE_MANAGEMENT = PARTNERSHIP_TYPES[:student_fee_management]
  ACADEMIC_AWARD_MAKING = PARTNERSHIP_TYPES[:academic_award_making]
  PLACEMENT = PARTNERSHIP_TYPES[:placement]

  included do
    enum :partnership_type, PARTNERSHIP_TYPES
  end

  def self.label_for(value)
    return if value.blank?

    I18n.t("partnership_types.#{value}", default: value.to_s.humanize)
  end

  def partnership_type_label
    PartnershipTypeEnum.label_for(partnership_type)
  end
end
