module UuidIdentifiable
  extend ActiveSupport::Concern

  included do
    validates :uuid, presence: true, uniqueness: true
    before_validation :ensure_uuid

    def to_param
      uuid
    end

  private

    def ensure_uuid
      self.uuid ||= SecureRandom.uuid
    end
  end
end
