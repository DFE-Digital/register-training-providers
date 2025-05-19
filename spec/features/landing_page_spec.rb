require "rails_helper"

RSpec.feature "landing page" do
  scenario "navigate to start" do
    given_i_am_on_the_start_page
    and_i_should_see_the_service_name
    and_i_should_see_the_phase_banner
    when_i_click_on("Sign in")
    then_i_am_take_to("/sign-in")
  end

  def given_i_am_on_the_start_page
    visit "/"
  end

  def when_i_click_on_sign_in
    page.click_on("Sign in")
  end

  alias_method :when_i_click_on, :click_on

  def and_i_should_see_the_service_name
    expect(page).to have_heading("h1", "Register of training providers")
    expect(page).to have_heading("h2", "Before you start")

    expect(page).to have_title("Register of training providers - GOV.UK")
  end

  def and_i_should_see_the_phase_banner
    expect(page).to have_phase_banner
  end
end
