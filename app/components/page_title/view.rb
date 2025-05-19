class PageTitle::View < ViewComponent::Base
  def initialize(text: nil, has_errors: false)
    @text = text
    @has_errors = has_errors
    super
  end

  def build_page_title
    [ build_error + build_title, I18n.t("service.name"), "GOV.UK" ].compact_blank.join(" - ")
  end

private

  attr_reader :text, :has_errors

  def build_error
    has_errors ? "Error: " : ""
  end

  def build_title
    text.presence || ""
  end
end
