require "rails_helper"

RSpec.describe PartnershipPolicy do
  subject { described_class }

  let(:reg) { build(:user, :reg) }
  let(:mr) { build(:user, :mr) }
  let(:bat) { build(:user, :bat) }
  let(:ro) { build(:user, :ro) }
  let(:partnership) { create(:partnership) }

  permissions :index?, :show? do
    it "permits every internal role" do
      [reg, mr, bat, ro].each do |user|
        expect(subject).to permit(user, partnership)
      end
    end

    it "permits an API user" do
      expect(subject).to permit(build(:user, api_user: true), partnership)
    end

    context "when the provider is discarded" do
      let(:partnership) { create(:partnership, provider: create(:provider, :discarded)) }

      it "denies every role" do
        [reg, mr, bat, ro, build(:user, api_user: true)].each do |user|
          expect(subject).not_to permit(user, partnership)
        end
      end
    end
  end

  permissions :new?, :create?, :edit?, :update?, :destroy? do
    it "permits REG and MR regardless of provider accreditation status" do
      expect(subject).to permit(reg, partnership)
      expect(subject).to permit(mr, partnership)
    end

    it "denies BAT, RO and API users" do
      [bat, ro, build(:user, api_user: true)].each do |user|
        expect(subject).not_to permit(user, partnership)
      end
    end

    context "when the provider is accredited" do
      let(:partnership) { create(:partnership, provider: create(:provider, :accredited)) }

      it "still permits REG and MR" do
        expect(subject).to permit(reg, partnership)
        expect(subject).to permit(mr, partnership)
      end
    end

    context "when the provider is archived" do
      let(:partnership) { create(:partnership, provider: create(:provider, :archived)) }

      it "denies REG and MR" do
        expect(subject).not_to permit(reg, partnership)
        expect(subject).not_to permit(mr, partnership)
      end
    end
  end
end
