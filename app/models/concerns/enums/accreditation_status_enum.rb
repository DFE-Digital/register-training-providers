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
end
