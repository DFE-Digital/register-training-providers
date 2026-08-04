class AccountsController < ApplicationController
  skip_after_action :verify_pundit_authorization

  def show
  end
end
