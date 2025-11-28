module Api
  class InfoController < Api::BaseController
    def show
      render(json: { status: "ok", version: { requested: current_version, latest: "v0" } })
    end
  end
end
