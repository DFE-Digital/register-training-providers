require "rails_helper"

RSpec.describe "users/index.html.erb", type: :view do
  let(:user_1) { build_stubbed(:user, first_name: "Alice") }
  let(:user_2) { build_stubbed(:user, first_name: "Bob") }
  let(:users) { [user_1, user_2] }
  let(:count) { users.size }
  let(:pagy) { Pagy.new(count: count, page: 1) }

  let(:pagination_component) { instance_double(PaginationDisplay::View) }

  before do
    assign(:records, users)
    assign(:pagy, pagy)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data with govuk_number count" do
    expect(view).to have_received(:page_data).with(title: "Support users (2)")
  end

  it "renders the add user button" do
    expect(rendered).to have_link("Add user", href: "/users/new")
  end

  it "renders the table headers" do
    expect(rendered).to have_selector("th", text: "Name")
    expect(rendered).to have_selector("th", text: "Email")
  end

  it "renders each user in the table" do
    users.each do |user|
      expect(rendered).to have_selector("td", text: user.name)
      expect(rendered).to have_selector("td", text: user.email)
    end
  end

  it "does not renders the pagination component" do
    expect(rendered).not_to have_pagination
  end

  context "when pagy count is over 25" do
    let(:count) { 1_000_000 }
    it "calls page_data with govuk_number count" do
      expect(view).to have_received(:page_data).with(title: "Support users (1,000,000)")
    end
    it "does renders the pagination component" do
      expect(rendered).to have_pagination
    end
  end
end
