require "rails_helper"

RSpec.feature "Internal role access" do
  %i[mr bat ro].each do |role|
    scenario "#{role} cannot access user administration" do
      given_i_am_authenticated(user: create(:user, role))

      when_i_visit("/users")
      then_i_am_shown_the_forbidden_page

      when_i_visit("/api_clients")
      then_i_am_shown_the_forbidden_page
    end
  end

  scenario "REG can access user administration" do
    given_i_am_authenticated(user: create(:user, :reg))

    when_i_visit("/users")
    then_i_am_on("/users")

    when_i_visit("/api_clients")
    then_i_am_on("/api_clients")
  end

  def when_i_visit(path)
    visit path
  end

  def then_i_am_shown_the_forbidden_page
    expect(page.status_code).to eq(403)
    expect(page).to have_content("You do not have permission to perform this action")
  end

  def then_i_am_on(path)
    expect(page).to have_current_path(path)
  end
end
