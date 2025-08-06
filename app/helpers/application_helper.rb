module ApplicationHelper
  def provider_page_data(provider)
    tag = []
    tag = [" ", govuk_tag(text: "Archived", classes: "govuk-tag__heading")] if provider.archived?

    tag = [" ", govuk_tag(text: "Soft deleted", colour: "red", classes: "govuk-tag__heading")] if provider.discarded?

    page_data(title: provider.operating_name, caption: "Provider", subtitle: "Provider",
              header: safe_join([provider.operating_name] + tag))
  end

  def page_data(title:, subtitle: nil, header: nil, header_size: "l", error: false, caption: nil)
    page_title = if error
                   "Error: #{title}"
                 else
                   title
                 end

    content_for(:page_title) { page_title }
    content_for(:page_subtitle) { subtitle }

    return { page_title: } if header == false

    span = caption.present? ? tag.span(caption, class: "govuk-caption-#{header_size}") : ""
    page_header = tag.h1(span + (header || title), class: "govuk-heading-#{header_size}")

    content_for(:page_header) { page_header }

    { page_title:, page_header: }
  end

  def govuk_number(number, precision: nil)
    if precision
      number_with_precision(number, precision: precision, delimiter: ",")
    else
      number_with_delimiter(number)
    end
  end

  def page_data_from_front_matter(yaml)
    parsed_yaml = YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true)&.transform_keys(&:to_sym)

    return unless parsed_yaml

    page_data(**parsed_yaml)
  end
end
