module UserSummary
  class ViewPreview < ViewComponent::Preview
    def view_support_user_with_no_delete_or_change_links
      render(UserSummary::View.new(
               title: "View support user", caption: "Support user", back_path: users_path, user: user
             ))
    end

    def view_support_user_with_no_delete_link
      render(UserSummary::View.new(
               title: "View support user", caption: "Support user", back_path: users_path, user: user, editable: true
             ))
    end

    def view_support_user
      render(UserSummary::View.new(
               title: "View support user", caption: "Support user", back_path: users_path, delete_path: "#delete",
               user: user, editable: true
             ))
    end

    def your_acccount
      render(UserSummary::View.new(
               title: "Your account", back_path: root_path, user: user
             ))
    end

  private

    def user
      @user ||= ::FactoryBot.build_stubbed(:user, :math_magician)
    end
  end
end
