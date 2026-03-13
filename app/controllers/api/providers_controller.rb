module Api
  class ProvidersController < Api::BaseController
    def index
      scope = Provider.kept

      scope = scope.where(updated_at: changed_since..) if changed_since.present?

      scope = scope.where(academic_years_active: [academic_year])

      providers = scope.order(:updated_at)

      data = providers.map do |p|
        p.as_json(
          only: %i[
            id operating_name provider_type code accreditation_status
          ]
        ).merge("updated_at" => p.updated_at.utc.iso8601)
      end

      render(json: { data: })
    end

  private

    def permitted_params
      params.permit(:changed_since, :academic_year)
    end

    def changed_since
      value = permitted_params[:changed_since]
      return nil if value.blank?

      Time.zone.parse(value)
    end

    def academic_year
      permitted_params[:academic_year].presence ||
        AcademicYearHelper.current_academic_year
    end
  end
end
