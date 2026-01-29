module UserSummary
  class View < ApplicationComponent
    attr_reader :title, :caption, :back_path, :delete_path, :user, :editable, :deletable

    def initialize(title:, back_path:, user:, caption: nil, delete_path: nil, editable: false, deletable: false)
      @title = title
      @caption = caption
      @back_path = back_path
      @delete_path = delete_path
      @user = user
      @editable = editable
      @deletable = deletable
      super()
    end

    def rows
      [
        { key: { text: "First name" },
          value: { text: @user.first_name },
          actions: editable ? [{ href: edit_user_path(user), visually_hidden_text: "first name" }] : [] },
        { key: { text: "Last name" },
          value: { text: @user.last_name },
          actions: editable ? [{ href: edit_user_path(user), visually_hidden_text: "last name" }] : [] },
        { key: { text: "Email address" },
          value: { text: @user.email },
          actions: editable ? [{ href: edit_user_path(user), visually_hidden_text: "email address" }] : [] },
      ]
    end

    def show_delete_link?
      delete_path.present?
    end

    def header
      user.name unless use_breadcrumbs?
    end

    def use_breadcrumbs?
      back_path == root_path
    end

    def last_signed_in_at
      return "User last signed in at #{user.last_signed_in_at.to_fs(:govuk_date_and_time)}" if user.last_signed_in_at.present?

      "User has never signed in"
    end
  end
end
