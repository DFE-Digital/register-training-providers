module FooterHelper
  def govuk_footer_component
    govuk_footer(
      meta_items_title: "Helpful links",
      meta_items: {
        Accessibility: accessibility_path,
        Cookies: cookies_path,
        "Privacy notice": privacy_path,
        "API documentation": api_docs_home_path,
      }
    )
  end
end
