module LivingDocs
  class BaseController < ApplicationController
    include HttpBasicAuth

    layout "living_docs"
  end
end
