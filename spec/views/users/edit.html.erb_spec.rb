require "rails_helper"

RSpec.describe "users/edit.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:goto) { nil }

  before do
    assign(:user, user)
    allow(view).to receive(:page_data)
    controller.params.merge!(goto:).compact!

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({ error: false,
                                                     header: false,
                                                     subtitle: "personal details",
                                                     title: "Change user" })
  end

  it "renders the continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "renders heading" do
    caption = "User - #{user.name}"
    heading = "Personal details"
    expect(rendered).to have_heading("h1", "#{caption}#{heading}")
  end

  it "renders the form" do
    expect(rendered).to have_selector("form")
    expect(rendered).to have_selector("input[name='user[first_name]']")
    expect(rendered).to have_selector("input[name='user[last_name]']")
    expect(rendered).to have_selector("input[name='user[email]']")
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: user_path(user))
  end

  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(user_path(user))
  end

  context "when goto is confirm" do
    let(:goto) { "confirm" }

    it "renders the back link" do
      expect(view.content_for(:breadcrumbs)).to have_back_link(user_check_path(user))
    end
  end

  context "with validation errors" do
    let(:user) do
      user = create(:user)
      user.first_name = ""
      user.last_name = ""
      user.email = ""
      user.valid?
      user
    end

    it "calls page_data with error" do
      expect(view).to have_received(:page_data).with({ error: true,
                                                       header: false,
                                                       subtitle: "personal details",
                                                       title: "Change user" })
    end

    it "renders the error summary" do
      expect(view.content_for(:page_alerts)).to have_error_summary(
        "Enter first name",
        "Enter last name",
        "Enter email address"
      )
    end
  end
end
