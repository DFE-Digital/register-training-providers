require "rails_helper"

RSpec.describe "users/new.html.erb", type: :view do
  let(:user) { User.new }

  before do
    assign(:user, user)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({ error: false, header: false, title: "Add support user" })
  end

  it "renders the continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "renders the form" do
    expect(rendered).to have_selector("form")
    expect(rendered).to have_selector("input[name='user[first_name]']")
    expect(rendered).to have_selector("input[name='user[last_name]']")
    expect(rendered).to have_selector("input[name='user[email]']")
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: users_path)
  end
  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(users_path)
  end

  context "with validation errors" do
    let(:user) do
      user = User.new
      user.valid?
      user
    end

    it "calls page_data with error" do
      expect(view).to have_received(:page_data).with({ error: true, header: false, title: "Add support user" })
    end

    it "renders the error summary" do
      expect(view.content_for(:page_alerts)).to have_error_summary(
        "Enter last name",
        "Enter last name",
        "Enter email address"
      )
    end
  end
end
