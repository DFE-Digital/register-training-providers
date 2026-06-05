module ApiDocsHelper
  def api_docs_endpoint_path(key, value)
    doc = key.delete_prefix("/")
    method = value.to_s
    raise KeyError, "no HTTP verb found in endpoint hash" if method.blank?

    Rails.application.routes.url_helpers.api_docs_page_path(
      method:,
      doc:
    )
  end

  def schema_description(value, row_data)
    descriptions = [value.to_s]
    if row_data[:enum].present?
      descriptions << "<br>".html_safe
      descriptions << "<br>".html_safe
      descriptions << "Possible values:"
      descriptions << content_tag(:ul, class: "govuk-list govuk-list--bullet") do
        row_data[:enum].map { |enum| content_tag(:li, enum) }.join.html_safe
      end
    end

    if row_data[:format].present?
      descriptions << "<br>".html_safe
      descriptions << "<br>".html_safe
      descriptions << "This field will be in the format #{row_data[:format]}."
    end

    if row_data[:nullable] == true
      descriptions << "<br>".html_safe
      descriptions << "<br>".html_safe
      descriptions << "This field can also be null."
    end

    { text: safe_join(descriptions) }
  end
end
