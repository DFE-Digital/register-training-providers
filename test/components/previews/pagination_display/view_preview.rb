require "govuk/components"

class PaginationDisplay::ViewPreview < ViewComponent::Preview
  def does_not_render
    render(PaginationDisplay::View.new(pagy: Pagy.new(count: 0)))
  end

  def beginning_of_1000_results
    render(PaginationDisplay::View.new(pagy: Pagy.new(count: 1000, page: 1)))
  end

  def middle_of_1000_results
    render(PaginationDisplay::View.new(pagy: Pagy.new(count: 1000, page: 20)))
  end

  def end_of_1000_results
    render(PaginationDisplay::View.new(pagy: Pagy.new(count: 1000, page: 40)))
  end
end
