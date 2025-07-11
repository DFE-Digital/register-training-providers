module AccreditationStatusValidator
  extend ActiveSupport::Concern

  included do
    validates :accreditation_status,
              presence: true,
              inclusion: { in: AccreditationStatusEnum::ACCREDITATION_STATUSES.values }
  end
end
