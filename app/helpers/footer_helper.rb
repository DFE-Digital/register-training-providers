module FooterHelper
  def govuk_footer_component
    meta_items = {
      Accessibility: accessibility_path,
      Cookies: cookies_path,
      "Privacy notice": privacy_path,
      "API documentation": api_docs_home_path,
      "Living documentation": living_docs_home_path,
    }

    govuk_footer(
      meta_items_title: "Helpful links",
      meta_items: meta_items
    )
  end
end
