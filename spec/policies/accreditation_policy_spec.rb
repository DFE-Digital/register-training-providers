require "rails_helper"

RSpec.describe AccreditationPolicy do
  subject { described_class }

  let(:reg) { build(:user, :reg) }
  let(:mr) { build(:user, :mr) }
  let(:bat) { build(:user, :bat) }
  let(:ro) { build(:user, :ro) }
  let(:accreditation) { create(:accreditation) }

  permissions :index?, :show? do
    it "permits every internal role" do
      [reg, mr, bat, ro].each do |user|
        expect(subject).to permit(user, accreditation)
      end
    end

    it "permits an API user" do
      expect(subject).to permit(build(:user, api_user: true), accreditation)
    end

    context "when the provider is discarded" do
      let(:accreditation) { create(:accreditation, provider: create(:provider, :discarded)) }

      it "denies every role" do
        [reg, mr, bat, ro, build(:user, api_user: true)].each do |user|
          expect(subject).not_to permit(user, accreditation)
        end
      end
    end
  end

  permissions :new?, :create?, :edit?, :update?, :destroy? do
    it "permits REG and MR" do
      expect(subject).to permit(reg, accreditation)
      expect(subject).to permit(mr, accreditation)
    end

    it "denies BAT, RO and API users" do
      [bat, ro, build(:user, api_user: true)].each do |user|
        expect(subject).not_to permit(user, accreditation)
      end
    end

    context "when the provider is archived" do
      let(:accreditation) { create(:accreditation, provider: create(:provider, :archived)) }

      it "denies REG and MR" do
        expect(subject).not_to permit(reg, accreditation)
        expect(subject).not_to permit(mr, accreditation)
      end
    end

    context "when the provider cannot be resolved" do
      let(:accreditation) { build(:accreditation, provider: nil) }

      it "denies every user rather than defaulting to an unsaved provider" do
        [reg, mr, bat, ro, build(:user, api_user: true)].each do |user|
          expect(subject).not_to permit(user, accreditation)
        end
      end
    end

    context "when creating an accreditation alongside a new provider" do
      let(:form) { AccreditationForm.new(provider_creation_mode: true, provider_type: "scitt") }

      it "permits REG and MR" do
        expect(subject).to permit(reg, form)
        expect(subject).to permit(mr, form)
      end

      it "denies BAT, RO and API users" do
        [bat, ro, build(:user, api_user: true)].each do |user|
          expect(subject).not_to permit(user, form)
        end
      end
    end
  end
end
