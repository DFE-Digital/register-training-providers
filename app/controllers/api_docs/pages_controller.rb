module ApiDocs
  class PagesController < BaseController
    helper_method :current_api_version, :next_api_version
    def home
    end

    def show
      doc = params[:doc]

      @endpoint = ApiDocs::ApiDocPresenter.new(
        spec: @spec = ApiDocs::OpenapiSpecification.endpoints["/#{doc}"],
        method: params[:method]
      )
    end
  end
end
