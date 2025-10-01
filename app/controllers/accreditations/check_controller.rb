module Accreditations
  class CheckController < ::CheckController
    include FormObjectSavePattern

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

    def find_existing_record
      provider.accreditations.kept.find(model_id)
    end

    def build_new_record
      provider.accreditations.build(model_attributes)
    end

    def model_attributes
      model.to_accreditation_attributes
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

    def provider
      @provider ||= Provider.find(params[:provider_id])
    end
  end
end
