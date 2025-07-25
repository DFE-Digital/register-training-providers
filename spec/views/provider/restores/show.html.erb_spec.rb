require "rails_helper"

RSpec.describe "providers/restores/show.html.erb", type: :view do
  let(:provider) { build_stubbed(:provider, :school) }
  let(:goto) { nil }

  before do
    assign(:provider, provider)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({
      title: "Confirm you want to restore #{provider.operating_name}",
      subtitle: "Restore provider",
      caption: "Restore provider",

    })
  end

  it "renders the restore provider button" do
    expect(rendered).to have_button("Restore provider")
  end

  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(provider_path(provider))
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: provider_path(provider))
  end
end
