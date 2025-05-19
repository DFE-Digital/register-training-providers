require "govuk/components"

class PageTitle::ViewPreview < ViewComponent::Preview
  def text_heading
    render(PageTitle::View.new(text: "Test heading"))
  end

  def text_heading_with_error
    render(PageTitle::View.new(text: "Test heading", has_errors: true))
  end
end
