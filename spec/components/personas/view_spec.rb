require "rails_helper"

RSpec.describe Personas::View, type: :component do
  alias_method :component, :page

  let(:reg_persona) { create(:user, :reg) }
  let(:mr_persona) { create(:user, :mr) }
  let(:bat_persona) { create(:user, :bat) }
  let(:ro_persona) { create(:user, :ro) }
  let(:inactive_persona) { create(:user, :reg, active: false) }
  let(:discarded_persona) do
    persona = create(:user, :ro)
    persona.discard
    persona
  end
  let(:api_persona) { create(:user, api_user: true) }
  let(:non_existing_persona) { build(:user, :ro) }
  let(:personas) { [reg_persona, mr_persona, bat_persona, ro_persona, inactive_persona, discarded_persona, api_persona, non_existing_persona] }

  before do
    render_inline(described_class.with_collection(personas))
  end

  it "renders personas' names" do
    personas.each { |persona| expect(component).to have_text(persona.name) }
  end

  it "renders role labels and descriptions" do
    expect(component).to have_text("Register")
    expect(component).to have_text("Service administration and full administrative access")
    expect(component).to have_text("Market Regulation")
    expect(component).to have_text("Operational management of accredited providers, accreditation and associated partnerships")
    expect(component).to have_text("Read-only")
    expect(component).to have_text("View-only access to authorised Register information")
  end

  it "colours the tag by role" do
    expect(component).to have_css(".govuk-tag--teal", text: "Register")
    expect(component).to have_css(".govuk-tag--blue", text: "Market Regulation")
    expect(component).to have_css(".govuk-tag--purple", text: "BAT Support")
    expect(component).to have_css(".govuk-tag--magenta", text: "Read-only")
    expect(component).to have_css(".govuk-tag--grey", text: "Inactive")
  end

  it "renders the status of special personas" do
    expect(component).to have_text("Soft deleted")
    expect(component).to have_text("API user")
    expect(component).to have_text("Non existence")
  end

  it "renders both the API user and read-only tags for an active API user" do
    api_user_heading = component.find("h2", text: api_persona.name)

    expect(api_user_heading).to have_css(".govuk-tag--yellow", text: "API user")
    expect(api_user_heading).to have_css(".govuk-tag--magenta", text: "Read-only")
  end

  it "renders the description of special personas" do
    expect(component).to have_text("No matching account")
    expect(component).to have_text("Soft deleted account")
    expect(component).to have_text("API client administration and view-only access to authorised Register information")
  end

  it "renders the BAT role description" do
    expect(component).to have_text("Operational management of non-accredited providers")
  end

  it "renders a sign-in button for each persona" do
    forms = component.find_all("form")

    expect(forms.count).to eq(personas.count)
    forms.each do |form|
      expect(form["action"]).to eq("/auth/developer/callback")
      expect(form).to have_button
    end
  end
end
