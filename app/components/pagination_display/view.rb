class PaginationDisplay::View < ViewComponent::Base
  include ApplicationHelper
  def initialize(pagy:)
    @pagy = pagy
    super
  end

  def render?
    pages > 1
  end

  attr_reader :pagy

  delegate :from, :to, :count, :pages, to: :pagy
end
