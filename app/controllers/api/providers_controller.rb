module Api
  class ProvidersController < Api::BaseController
    def index
      scope = Provider.kept

      scope = scope.where(updated_at: changed_since..) if changed_since.present?

      scope = scope
        .joins(:academic_cycles)
        .where(academic_cycles: { id: AcademicCycle.for_year(academic_year) })

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
      year = permitted_params[:academic_year].to_s[/\A2\d{3}\z/]

      year ? year.to_i : AcademicYearHelper.current_academic_year
    end
  end
end
