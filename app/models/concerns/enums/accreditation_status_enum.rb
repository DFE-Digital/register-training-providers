module AccreditationStatusEnum
  extend ActiveSupport::Concern

  ACCREDITATION_STATUSES = {
    accredited: "accredited",
    unaccredited: "unaccredited"
  }.freeze

  ACCREDITED = ACCREDITATION_STATUSES[:accredited]
  UNACCREDITED = ACCREDITATION_STATUSES[:unaccredited]
  included do
    enum :accreditation_status, ACCREDITATION_STATUSES
  end

  def accreditation_status_label
    I18n.t("providers.accreditation_statuses.#{accreditation_status}")
  end
end
