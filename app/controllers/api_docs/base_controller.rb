module ApiDocs
  class BaseController < ActionController::Base
    include HttpBasicAuth

    layout "api_docs"
  end
end
