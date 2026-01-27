require "rails_helper"

RSpec.describe UserSummary::View, type: :component do
  let(:user) { FactoryBot.build_stubbed(:user, :math_magician) }

  describe "preview" do
    let(:expected_summary_rows) do
      [
        { label: "First name", value: user.first_name, link_text: "Change first name", href: "/users/#{user.id}/edit" },
        { label: "Last name", value: user.last_name, link_text: "Change last name", href: "/users/#{user.id}/edit" },
        { label: "Email address", value: user.email, link_text: "Change email address", href: "/users/#{user.id}/edit" }
      ]
    end

    describe "view support user" do
      subject { render_preview(:view_user) }

      it "renders heading" do
        expect(subject).to have_heading("h1", user.name)
      end

      it "renders back link" do
        expect(subject).to have_back_link("/users")
      end

      it "renders summary list rows" do
        expect(subject).to have_css("dl.govuk-summary-list")

        expected_summary_rows.each do |row|
          expect(subject).to have_css("dt.govuk-summary-list__key", text: row[:label])
          expect(subject).to have_css("dd.govuk-summary-list__value", text: row[:value])
          expect(subject).to have_link(row[:link_text], href: row[:href])
        end
      end

      it "renders delete link" do
        expect(subject).to have_link("Delete user", href: "#delete")
      end
    end

    describe "your_account" do
      subject { render_preview(:your_account) }

      it "renders heading" do
        expect(subject).to have_heading("h1", "Your account")
      end

      it "renders home link" do
        expect(subject).to have_link("Home", href: "/")
      end

      it "renders summary list rows" do
        expect(subject).to have_css("dl.govuk-summary-list")

        expected_summary_rows.each do |row|
          expect(subject).to have_css("dt.govuk-summary-list__key", text: row[:label])
          expect(subject).to have_css("dd.govuk-summary-list__value", text: row[:value])
          expect(subject).not_to have_link(row[:link_text], href: row[:href])
        end
      end

      it "does not renders delete link" do
        expect(subject).not_to have_link("Delete user", href: "#delete")
      end
    end
  end
end
