require "rails_helper"

RSpec.describe UserHelper, type: :helper do
  let(:user) { build_stubbed(:user, active:, api_user:) }
  let(:active) { true }
  let(:api_user) { false }

  describe "#status_tags" do
    context "for an active user" do
      it { expect(helper.status_tags(user)).to eq("<strong class=\"govuk-tag govuk-tag--teal\">Active</strong>") }
    end

    context "for an inactive user" do
      let(:active) { false }

      it { expect(helper.status_tags(user)).to eq("<strong class=\"govuk-tag govuk-tag--grey\">Not active</strong>") }
    end

    context "for an api user" do
      let(:api_user) { true }

      context "that is active" do
        it { expect(helper.status_tags(user)).to eq("<strong class=\"govuk-tag govuk-tag--teal\">Active</strong><strong class=\"govuk-tag govuk-tag--yellow\">API user</strong>") }
      end

      context "that is inactive" do
        let(:active) { false }

        it { expect(helper.status_tags(user)).to eq("<strong class=\"govuk-tag govuk-tag--grey\">Not active</strong><strong class=\"govuk-tag govuk-tag--yellow\">API user</strong>") }
      end
    end
  end
end
