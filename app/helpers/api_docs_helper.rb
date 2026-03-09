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
end
