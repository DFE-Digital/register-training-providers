class UsersController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @records = pagy(User.kept.order_by_first_then_last_name)
  end
end
