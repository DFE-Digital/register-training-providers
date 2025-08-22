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

  class_methods do
    def find(id)
      if id.to_s.match?(/\A[0-9a-f\-]{36}\z/i)
        find_by!(uuid: id)
      else
        super
      end
    end
  end
end
