require "rails_helper"

RSpec.feature "landing page" do
  scenario "navigate to start" do
    given_i_am_an_authenticated_user
    when_i_click_on("Your account")
    then_i_am_taken_to("/account")
  end

  def and_the_table_has_header_for_name_and_email
    expect(subject).to have_css("dt.govuk-summary-list__key", text: "First name")
    expect(subject).to have_css("dd.govuk-summary-list__value", text: current_user.first_name)
    expect(subject).to have_css("dt.govuk-summary-list__key", text: "Last name")
    expect(subject).to have_css("dd.govuk-summary-list__value", text: current_user.last_name)
    expect(subject).to have_css("dt.govuk-summary-list__key", text: "Email address")
    expect(subject).to have_css("dd.govuk-summary-list__value", text: current_user.email)
  end
end
