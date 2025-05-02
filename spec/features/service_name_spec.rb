require "rails_helper"

RSpec.feature "Service name" do
  scenario "navigate to start" do
    given_i_am_on_the_start_page
    and_i_should_see_the_service_name_in_the_header
    when_i_click_on("Register of training providers")
    then_i_am_take_to("/")
  end

  def given_i_am_on_the_start_page
    visit "/"
  end

  alias_method :when_i_click_on, :click_on

  def and_i_should_see_the_service_name_in_the_header
    expect(page).to have_service_name_in_the_header
  end
end
