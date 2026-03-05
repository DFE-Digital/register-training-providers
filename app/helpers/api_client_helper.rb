module ApiClientHelper
  STATUS_COLOURS = {
    active: "turquoise",
    expired: "grey",
    revoked: "orange"
  }.freeze

  def api_client_name_and_creator(api_client)
    raw("#{govuk_link_to(api_client.name, href: api_client_path(api_client))}
    <p class=\"govuk-hint govuk-!-font-size-16 govuk-!-margin-bottom-0 govuk-!-margin-top-1\">
    #{api_client.current_authentication_token.created_by.name}</p>")
  end

  def token_status_colour(status)
    STATUS_COLOURS[status.to_sym]
  end

  def api_client_page_data(title:, subtitle: nil, header: nil, header_size: "l", error: false, caption: nil,
                           status: nil)
    page_title = if error
                   "Error: #{title}"
                 else
                   title
                 end

    content_for(:page_title) { page_title }
    content_for(:page_subtitle) { subtitle }

    return { page_title: } if header == false

    span = caption.present? ? tag.span(caption, class: "govuk-caption-#{header_size}") : ""
    status_tag = if status.present?
                   tag.strong(status.humanize,
                              class: "govuk-tag govuk-tag--#{token_status_colour(status)} govuk-tag__heading")
                 else
                   ""
                 end
    page_header = tag.h1(span + (header || title) + status_tag, class: "govuk-heading-#{header_size}")

    content_for(:page_header) { page_header }

    { page_title:, page_header: }
  end
end
