module AccreditationStatusEnum
  extend ActiveSupport::Concern

  ACCREDITATION_STATUSES = {
    accredited: "accredited",
    unaccredited: "unaccredited"
  }.freeze

  included do
    enum :accreditation_status, ACCREDITATION_STATUSES
  end
end
