module FormObjectSavePattern
  extend ActiveSupport::Concern

  # Override save method for form objects that need conversion to ActiveRecord attributes
  def save
    if model_id.present?
      update_existing_record
    else
      create_new_record
    end
  end

private

  def update_existing_record
    record = find_existing_record
    authorize record

    if record.update(model_attributes)
      cleanup_and_redirect_success
    else
      redirect_to back_path
    end
  end

  def create_new_record
    record = build_new_record
    authorize record

    if record.save
      cleanup_and_redirect_success
    else
      redirect_to back_path
    end
  end

  def cleanup_and_redirect_success
    current_user.clear_temporary(model_class, purpose:)
    redirect_to success_path, flash: flash_message
  end

  def find_existing_record
    raise NotImplementedError, "#{self.class.name} must implement #find_existing_record"
  end

  def build_new_record
    raise NotImplementedError, "#{self.class.name} must implement #build_new_record"
  end

  def model_attributes
    raise NotImplementedError, "#{self.class.name} must implement #model_attributes"
  end
end
