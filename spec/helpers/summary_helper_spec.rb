require "rails_helper"

RSpec.describe SummaryHelper, type: :helper do
  describe "#optional_value" do
    context "when the value is present" do
      it "returns a hash with the value as text" do
        expect(helper.optional_value("Some Value")).to eq({ text: "Some Value" })
      end
    end

    context "when the value is blank" do
      it "returns the not_entered hash" do
        expect(helper.optional_value("")).to eq({ text: "Not entered", classes: "govuk-hint" })
      end

      it "returns the not_entered hash when nil" do
        expect(helper.optional_value(nil)).to eq({ text: "Not entered", classes: "govuk-hint" })
      end
    end
  end

  describe "#not_entered" do
    it "returns the expected not entered hash" do
      expect(helper.not_entered).to eq({ text: "Not entered", classes: "govuk-hint" })
    end
  end

  describe "#user_rows" do
    let(:user) { build_stubbed(:user, last_signed_in_at:) }
    let(:last_signed_in_at) { nil }
    let(:change_path) { "/users/#{user.id}/edit" }

    context "for a new user" do
      before { allow(user).to receive(:persisted?).and_return(false) }

      let(:change_path) { "/users/new?goto=confirm" }

      it "returns the expected rows" do
        expect(helper.user_rows(user, change_path)).to eq([
          {
            key: { text: "First name" },
            value: { text: user.first_name },
            actions: [{ href: change_path, visually_hidden_text: "first name" }]
          },
          {
            key: { text: "Last name" },
            value: { text: user.last_name },
            actions: [{ href: change_path, visually_hidden_text: "last name" }]
          },
          {
            key: { text: "Email address" },
            value: { text: user.email },
            actions: [{ href: change_path, visually_hidden_text: "email address" }]
          },
          {
            key: { text: "Is the account an API user?" },
            value: { text: "No" },
            actions: [{ href: change_path, visually_hidden_text: "is the account an api user" }]
          }
        ])
      end
    end

    context "for a user that hasn't signed in" do
      it "returns the expected rows" do
        expect(helper.user_rows(user, change_path)).to eq([
          {
            key: { text: "First name" },
            value: { text: user.first_name },
            actions: [{ href: change_path, visually_hidden_text: "first name" }]
          },
          {
            key: { text: "Last name" },
            value: { text: user.last_name },
            actions: [{ href: change_path, visually_hidden_text: "last name" }]
          },
          {
            key: { text: "Email address" },
            value: { text: user.email },
            actions: [{ href: change_path, visually_hidden_text: "email address" }]
          },
          {
            key: { text: "Is the account an API user?" },
            value: { text: "No" },
            actions: [{ href: change_path, visually_hidden_text: "is the account an api user" }]
          },
          {
            key: { text: "Is the account active?" },
            value: { text: "Yes" },
            actions: [{ href: change_path, visually_hidden_text: "is the account active" }]
          }
        ])
      end
    end

    context "for a user that has signed in" do
      let(:last_signed_in_at) { Time.zone.now }

      it "returns the expected rows" do
        expect(helper.user_rows(user, change_path)).to eq([
          {
            key: { text: "First name" },
            value: { text: user.first_name }
          },
          {
            key: { text: "Last name" },
            value: { text: user.last_name }
          },
          {
            key: { text: "Email address" },
            value: { text: user.email }
          },
          {
            key: { text: "Is the account an API user?" },
            value: { text: "No" },
            actions: [{ href: change_path, visually_hidden_text: "is the account an api user" }]
          },
          {
            key: { text: "Is the account active?" },
            value: { text: "Yes" },
            actions: [{ href: change_path, visually_hidden_text: "is the account active" }]
          }
        ])
      end
    end
  end
end
