require "rails_helper"

RSpec.describe SeedPersonas do
  it "creates the configured personas with their roles, flags and status" do
    described_class.call

    expect(Persona.find_by(email: "test1@education.gov.uk").role).to eq("reg")
    expect(Persona.find_by(email: "test2@education.gov.uk").role).to eq("mr")
    expect(Persona.find_by(email: "test3@education.gov.uk").role).to eq("bat")
    expect(Persona.find_by(email: "test8@education.gov.uk").role).to eq("ro")
    expect(Persona.find_by(email: "test5@education.gov.uk")).to be_api_user
    expect(Persona.find_by(email: "systemadmin@education.gov.uk")).to be_system_admin
    expect(Persona.find_by(email: "test4@education.gov.uk")).to be_discarded
  end

  it "does not provision a system administrator when system admins are excluded" do
    described_class.call(include_system_admin: false)

    expect(Persona.find_by(email: "systemadmin@education.gov.uk")).not_to be_system_admin
  end

  it "keeps the API personas as API users when system admins are excluded" do
    described_class.call(include_system_admin: false)

    persona = Persona.find_by(email: "test5@education.gov.uk")

    expect(persona).to be_api_user
    expect(persona.role).to eq(UserRoleEnum::RO)
  end

  it "leaves an existing system administrator flagged when system admins are excluded" do
    described_class.call
    described_class.call(include_system_admin: false)

    expect(Persona.find_by(email: "systemadmin@education.gov.uk")).to be_system_admin
  end
end
