class ProvidersController < ApplicationController
  def index
  end

  def new
    @form = Providers::IsTheProviderAccredited.new
  end

  def create
  end
end
