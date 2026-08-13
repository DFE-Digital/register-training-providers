module LivingDocs
  class BaseController < ActionController::Base
    include HttpBasicAuth

    layout "living_docs"
  end
end
