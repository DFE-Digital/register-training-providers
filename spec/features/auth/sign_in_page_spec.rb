require "rails_helper"

feature "sign in page" do
  before do
    visit "/sign-in"
  end

  scenario "navigate to sign in", env: { sign_in_method: "persona"} do
    expect(page).to have_heading("h1", "Sign in to Register of training providers")
    expect(page).to have_title("Sign in to Register of training providers - Register of training providers - GOV.UK")
    expect(page).to have_button("Sign in using Persona")
  end

  scenario "navigate to sign in", env: { sign_in_method: nil } do
    expect(page).to have_heading("h1", "Sign in to Register of training providers")
    expect(page).to have_title("Sign in to Register of training providers - Register of training providers - GOV.UK")
    expect(page).to have_button("Sign in using DfE Sign-in")
  end

  scenario "navigate to sign in", env: { sign_in_method: "dfe-sign-in" } do
    expect(page).to have_heading("h1", "Sign in to Register of training providers")
    expect(page).to have_title("Sign in to Register of training providers - Register of training providers - GOV.UK")
    expect(page).to have_button("Sign in using DfE Sign-in")
  end

  scenario "navigate to sign in", env: { sign_in_method: "otp"} do
    expect(page).to have_heading("h1", "Sign in to Register of training providers")
    expect(page).to have_title("Sign in to Register of training providers - Register of training providers - GOV.UK")
    expect(page).to have_button("Sign in using your email")
  end
end
