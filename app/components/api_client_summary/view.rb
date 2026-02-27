module ApiClientSummary
  class View < ApplicationComponent
    attr_reader :title, :caption, :back_path, :delete_path, :api_client, :editable, :deletable

    def initialize(title:, back_path:, api_client:, caption: nil, delete_path: nil, editable: false)
      @title = title
      @caption = caption
      @back_path = back_path
      @delete_path = delete_path
      @api_client = api_client
      @editable = editable
      super()
    end

    def rows
      [
        { key: { text: "Client name" },
          value: { text: api_client.name },
          actions: editable ? [{ href: edit_api_client_path(api_client), visually_hidden_text: "client name" }] : [] },
        { key: { text: "Expiry date" },
          value: { text: api_client.current_authentication_token.expires_at.to_fs(:govuk) }, }
      ]
    end

    def header
      api_client.name unless use_breadcrumbs?
    end

    def use_breadcrumbs?
      back_path == root_path
    end
  end
end
