class ActivityController < ApplicationController
  include Pagy::Backend

  def index
    audits = AuditsQuery.call
    @pagy, @audits = pagy(audits, limit: 25)
  end
end
