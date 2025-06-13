module CheckYourAnswers
  class ViewPreview < ViewComponent::Preview
    def new_user_check_your_answers
      render(CheckYourAnswers::View.new(
               rows: rows, subtitle: "Add user support", caption: "Add user support", back_path: back_path,
               save_button_text: "Save user", save_path: save_path, cancel_path: cancel_path
             ))
    end

  private

    def new_user
      @new_user ||= ::FactoryBot.build(:user)
    end

    def rows
      [
        { key: { text: "First name" }, value: { text: new_user.first_name } },
        { key: { text: "Last name" }, value: { text: new_user.last_name } },
        { key: { text: "Email address" }, value: { text: new_user.email } },
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
