require "rails_helper"

RSpec.describe Personas::View, type: :component do
  alias_method :component, :page

  let(:persona1) { create(:user) }
  let(:persona2) do persona = create(:user)
                    persona.discard
                    persona
                  end
  let(:persona3) { build(:user, :discarded) }
  let(:personas) { [persona1, persona2, persona3] }

  before do
    render_inline(described_class.with_collection(personas))
  end

  it "renders personas' name" do
    expect(component).to have_text(persona1.name)
    expect(component).to have_text(persona2.name)
    expect(component).to have_text(persona3.name)
  end

  it "renders a sign-in button to login" do

    items = component.find_all("form").each do |form|
      expect(form["action"]).to eq("/auth/developer/callback")
      expect(form).to have_button
    end
    expect(items.count).to eq(3)
  end
end
