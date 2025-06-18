module SaveAsTemporary
  extend ActiveSupport::Concern

  def save_as_temporary!(created_by:, purpose:, expires_in: 1.day)
    raise ActiveRecord::RecordInvalid, self if respond_to?(:valid?) && !valid?

    TemporaryRecord.upsert(
      {
        record_type: self.class.name,
        data: serializable_hash,
        created_by: created_by.id,
        expires_at: Time.current + expires_in,
        purpose: purpose,
        updated_at: Time.current
      },
      unique_by: %i[created_by record_type purpose]
    )
  end
end
