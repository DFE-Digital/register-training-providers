module ApiClientHelper
  STATUS_COLOURS = {
    active: "green",
    expired: "grey",
    revoked: "orange"
  }.freeze

  def api_client_name_and_creator(api_client)
    raw("#{govuk_link_to(api_client.name, href: api_client_path(api_client))}
    <p class=\"govuk-hint govuk-!-font-size-16 govuk-!-margin-bottom-0 govuk-!-margin-top-1\">
    #{api_client.current_authentication_token.created_by.name}</p>")
  end

  def token_status_colour(api_client)
    STATUS_COLOURS[api_client.current_authentication_token.status.to_sym]
  end
end
