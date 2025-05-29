module ApplicationHelper
  def page_data(title:, header: nil, header_size: "l", error: false)
    page_title = if error
                   "Error: #{title}"
    else
      title
    end

    content_for(:page_title) { page_title }

    return { page_title: } if header == false

    page_header = tag.h1(header || title, class: "govuk-heading-#{header_size}")

    content_for(:page_header) { page_header }

    { page_title:, page_header: }
  end

  def govuk_number(number, precision: nil)
    if precision
      number_with_precision(number, precision: precision, delimiter: ',')
    else
      number_with_delimiter(number)
    end
  end
end
