module CheckYourAnswers
  class ViewPreview < ViewComponent::Preview
    def new_user_check_your_answers
      render(CheckYourAnswers::View.new(
               rows: new_user_rows, subtitle: "Add support user", caption: "Add support user", back_path: back_path,
               save_button_text: "Save user", save_path: save_path, cancel_path: cancel_path, method: :post
             ))
    end

    def existing_user_check_your_answers
      render(CheckYourAnswers::View.new(
               rows: existing_user_rows, subtitle: "Support user", caption: "Support user", back_path: back_path,
               save_button_text: "Save user", save_path: save_path, cancel_path: cancel_path, method: :patch
             ))
    end

  private

    def new_user
      @new_user ||= ::FactoryBot.build(:user)
    end

    def new_user_rows
      [
        { key: { text: "First name" }, value: { text: new_user.first_name }, actions: [{ href: new_user_path }] },
        { key: { text: "Last name" }, value: { text: new_user.last_name }, actions: [{ href: new_user_path }] },
        { key: { text: "Email address" }, value: { text: new_user.email }, actions: [{ href: new_user_path }] },
      ]
    end

    def existing_user
      @existing_user ||= ::FactoryBot.build_stubbed(:user)
    end

    def existing_user_rows
      [
        { key: { text: "First name" },
          value: { text: existing_user.first_name },
          actions: [{ href: edit_user_path(existing_user) }] },
        { key: { text: "Last name" },
          value: { text: existing_user.last_name },
          actions: [{ href: edit_user_path(existing_user) }] },
        { key: { text: "Email address" },
          value: { text: existing_user.email },
          actions: [{ href: edit_user_path(existing_user) }] },
      ]
    end

    def back_path
      "/some/path"
    end

    def save_path
      "/save/path"
    end

    def cancel_path
      "/cancel/path"
    end
  end
end
