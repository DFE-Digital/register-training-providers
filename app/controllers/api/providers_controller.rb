module Api
  class ProvidersController < Api::BaseController
    def index
      providers = Provider.kept.order(:updated_at)

      data = providers.map do |p|
        p.as_json(
          only: %i[
            id operating_name provider_type code accreditation_status
          ]
        ).merge("updated_at" => p.updated_at.iso8601)
      end

      render(json: { data: })
    end
  end
end
