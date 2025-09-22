module Accreditations
  class CheckController < ::CheckController

  private

    def model_class
      AccreditationForm
    end

    def model_id
      @model_id ||= params[:id] || params[:accreditation_id]
    end

    def purpose
      model_id.present? ? :"edit_accreditation_#{model_id}" : :"create_accreditation_#{provider.id}"
    end

    def model
      @model ||= current_user.load_temporary(model_class, purpose:)
    end

    def success_path
      provider_accreditations_path(provider)
    end

    def save
      if model_id.present?
        accreditation = provider.accreditations.kept.find(model_id)
        authorize accreditation

        if accreditation.update(model.to_accreditation_attributes)
          current_user.clear_temporary(model_class, purpose:)
          redirect_to success_path, flash: flash_message
        else
          redirect_to back_path
        end
      else
        accreditation = provider.accreditations.build(model.to_accreditation_attributes)
        authorize accreditation

        if accreditation.save
          current_user.clear_temporary(model_class, purpose:)
          redirect_to success_path, flash: flash_message
        else
          redirect_to back_path
        end
      end
    end

    def new_model_path(query_params = {})
      new_accreditation_path(query_params.merge(provider_id: provider.id))
    end

    def edit_model_path(query_params = {})
      accreditation = provider.accreditations.kept.find(model_id)
      edit_accreditation_path(accreditation, query_params.merge(provider_id: provider.id))
    end

    def new_model_check_path
      accreditation_confirm_path(provider_id: provider.id)
    end

    def model_check_path
      accreditation = provider.accreditations.kept.find(model_id)
      accreditation_check_path(accreditation, provider_id: provider.id)
    end
  end
end
