module  Providers
  class AcademicYearsController < CheckController
    helper_method :back_path

    def edit
      provider = Provider.find(params[:provider_id])

      @form = current_user.load_temporary(Providers::AcademicYearsForm, purpose: :edit_provider_academic_years)

      authorize provider, :edit?
      if @form.academic_year_ids.blank?
        @form.academic_year_ids = provider.academic_year_ids
      end

      @academic_years = AcademicYear.next_and_older
    end

    def update
      provider = Provider.find(params[:provider_id])
      @form = Providers::AcademicYearsForm.new(create_new_academic_years_params.merge(provider_id: provider.id))

      if @form.valid?
        @form.save_as_temporary!(created_by: current_user, purpose: :edit_provider_academic_years)

        redirect_to provider_academic_years_check_path(provider)
      else
        render(:edit)
      end
    end

  private

    def back_path
      if params[:goto] == "confirm"
        provider_academic_years_check_path
      else
        providers_path
      end
    end

    def create_new_academic_years_params
      params.expect(provider: { academic_year_ids: [] }).tap do |param|
        param[:academic_year_ids].reject!(&:blank?)
      end
    end
  end
end
