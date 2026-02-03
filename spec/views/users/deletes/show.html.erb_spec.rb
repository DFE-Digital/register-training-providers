RSpec.describe "users/deletes/show.html.erb", type: :view do
  let(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({
      caption: "Delete user",
      title: "Confirm you want to delete user",
      header: "Confirm you want to delete #{user.name}"
    })
  end

  it "renders the delete user button" do
    expect(rendered).to have_button("Delete user")
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: user_path(user))
  end
  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(user_path(user))
  end

  it "renders the warning text" do
    expect(rendered).to have_warning_text("Deleting a user is permanent – you cannot undo it.")
  end
end
