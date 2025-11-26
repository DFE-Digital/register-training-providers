module Api
  class ProvidersController < Api::BaseController
    def index
      scope = Provider.kept

      scope = scope.where(updated_at: changed_since..) if changed_since.present?

      providers = scope.order(:updated_at)

      data = providers.map do |p|
        p.as_json(
          only: %i[
            id operating_name provider_type code accreditation_status
          ]
        ).merge("updated_at" => p.updated_at.iso8601)
      end

      render(json: { data: })
    end

  private

    def permitted_params
      params.permit(:changed_since)
    end

    def changed_since
      value = permitted_params[:changed_since]
      return nil if value.blank?

      Time.zone.parse(value)
    end
  end
end
