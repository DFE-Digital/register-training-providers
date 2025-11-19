module Api
  class InfoController < Api::BaseController
    def show
      render(json: { status: "ok", version: { requested: current_version, latest: "v1" } })
    end
  end
end
