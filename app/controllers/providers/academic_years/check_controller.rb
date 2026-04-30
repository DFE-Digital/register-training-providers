module Providers
  module AcademicYears
    class CheckController < ApplicationController
      def show
        @form = current_user.load_temporary(Providers::AcademicYearsForm, purpose: :edit_provider_academic_years)

        authorize provider, :edit?

        if @form.invalid? || @form.provider_id.nil? || @form.provider_id != provider.id
          current_user.clear_temporary(Providers::AcademicYearsForm, purpose: :edit_provider_academic_years)
          redirect_to edit_provider_academic_years_path(provider)
          nil
        end
      end

      def update
        @form = current_user.load_temporary(Providers::AcademicYearsForm,
                                            purpose: :edit_provider_academic_years)

        authorize provider, :edit?

        if @form.invalid? || @form.provider_id.nil? || @form.provider_id != provider.id
          current_user.clear_temporary(Providers::AcademicYearsForm, purpose: :edit_provider_academic_years)
          redirect_to edit_provider_academic_years_path(provider)
          return
        end

        @form.save!
        redirect_to provider_path(provider),
                    flash: { success: I18n.t("flash_message.success.check.academic_years.update") }
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
