module ApiClientSummary
  class View < ApplicationComponent
    include ApiClientHelper

    attr_reader :title, :caption, :back_path, :delete_path, :revoke_path, :api_client, :editable, :deletable

    def initialize(title:, back_path:, api_client:, caption: nil, delete_path: nil, editable: false, revoke_path: nil)
      @title = title
      @caption = caption
      @back_path = back_path
      @delete_path = delete_path
      @revoke_path = revoke_path
      @api_client = api_client
      @editable = editable
      super()
    end

    def rows
      api_client_rows(api_client:, editable:)
    end

    def header
      api_client.name unless use_breadcrumbs?
    end

    def use_breadcrumbs?
      back_path == root_path
    end
  end
end
