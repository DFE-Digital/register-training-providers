module ApiDocs
  class PagesController < BaseController
    helper_method :current_api_version, :next_api_version
    def home
    end

    def show
      @endpoint = ApiDocs::ApiDocPresenter.new(
        doc: params[:doc],
        method: params[:method]
      )
    end
  end
end
