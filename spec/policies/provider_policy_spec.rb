require "rails_helper"

RSpec.describe ProviderPolicy do
  subject { described_class }

  let(:reg) { build(:user, :reg) }
  let(:mr) { build(:user, :mr) }
  let(:bat) { build(:user, :bat) }
  let(:ro) { build(:user, :ro) }
  let(:api_user) { build(:user, api_user: true) }
  let(:accredited_provider) { build(:provider, :accredited) }
  let(:unaccredited_provider) { build(:provider, accreditation_status: :unaccredited) }

  permissions :index? do
    it "permits every internal role" do
      provider = create(:provider)

      [reg, mr, bat, ro].each do |user|
        expect(subject).to permit(user, provider)
      end
    end

    it "permits an API user" do
      expect(subject).to permit(api_user, create(:provider))
    end
  end

  permissions :show? do
    it "permits every internal role" do
      provider = create(:provider)

      [reg, mr, bat, ro].each do |user|
        expect(subject).to permit(user, provider)
      end
    end

    it "permits an API user for read-only access" do
      expect(subject).to permit(api_user, create(:provider))
    end

    it "denies a discarded provider" do
      expect(subject).not_to permit(reg, create(:provider, :discarded))
    end
  end

  permissions :edit?, :update? do
    it "permits REG on any kept provider" do
      expect(subject).to permit(reg, accredited_provider)
      expect(subject).to permit(reg, unaccredited_provider)
    end

    it "permits MR on an accredited provider" do
      expect(subject).to permit(mr, accredited_provider)
    end

    it "denies MR on an unaccredited provider" do
      expect(subject).not_to permit(mr, unaccredited_provider)
    end

    it "permits BAT on an unaccredited provider" do
      expect(subject).to permit(bat, unaccredited_provider)
    end

    it "denies BAT on an accredited provider" do
      expect(subject).not_to permit(bat, accredited_provider)
    end

    it "denies RO, API users, archived providers and discarded providers" do
      expect(subject).not_to permit(ro, accredited_provider)
      expect(subject).not_to permit(api_user, accredited_provider)
      expect(subject).not_to permit(reg, create(:provider, :archived))
      expect(subject).not_to permit(reg, create(:provider, :discarded))
    end
  end

  permissions :create? do
    it "permits REG for any new provider" do
      expect(subject).to permit(reg, build(:provider, accreditation_status: :accredited))
      expect(subject).to permit(reg, build(:provider, accreditation_status: :unaccredited))
    end

    it "permits MR only when the provider will be accredited" do
      expect(subject).to permit(mr, build(:provider, accreditation_status: :accredited))
      expect(subject).not_to permit(mr, build(:provider, accreditation_status: :unaccredited))
    end

    it "permits BAT only when the provider will be unaccredited" do
      expect(subject).to permit(bat, build(:provider, accreditation_status: :unaccredited))
      expect(subject).not_to permit(bat, build(:provider, accreditation_status: :accredited))
    end

    it "permits REG, MR and BAT but not RO while the accreditation choice is not yet made" do
      form = double(new_record?: true)

      [reg, mr, bat].each do |user|
        expect(subject).to permit(user, form)
      end
      expect(subject).not_to permit(ro, form)
    end

    it "denies RO, API users and persisted providers" do
      expect(subject).not_to permit(ro, build(:provider))
      expect(subject).not_to permit(api_user, build(:provider))
      expect(subject).not_to permit(reg, create(:provider))
    end
  end

  permissions :destroy?, :restore? do
    it "permits REG on an archived provider" do
      expect(subject).to permit(reg, create(:provider, :archived))
    end

    it "denies MR, BAT, RO and API users" do
      provider = create(:provider, :archived)

      [mr, bat, ro, api_user].each do |user|
        expect(subject).not_to permit(user, provider)
      end
    end

    it "denies a provider that is not archived" do
      expect(subject).not_to permit(reg, create(:provider))
    end
  end

  permissions :archive? do
    it "permits the owning role on an inactive provider" do
      expect(subject).to permit(reg, create(:provider, :with_current_inactive_period))
      expect(subject).to permit(bat, create(:provider, :with_current_inactive_period))
    end

    it "denies an active provider" do
      expect(subject).not_to permit(reg, create(:provider))
    end

    it "denies an archived provider" do
      expect(subject).not_to permit(reg, create(:provider, :archived))
    end

    it "denies BAT an accredited provider" do
      provider = create(:provider, :accredited, :with_current_inactive_period)

      expect(subject).not_to permit(bat, provider)
    end
  end

  permissions :manage_accreditations?, :manage_partnerships? do
    it "permits REG and MR on a kept provider" do
      provider = create(:provider)

      expect(subject).to permit(reg, provider)
      expect(subject).to permit(mr, provider)
    end

    it "denies BAT, RO and API users" do
      provider = create(:provider)

      [bat, ro, api_user].each do |user|
        expect(subject).not_to permit(user, provider)
      end
    end

    it "denies archived and discarded providers" do
      expect(subject).not_to permit(reg, create(:provider, :archived))
      expect(subject).not_to permit(reg, create(:provider, :discarded))
    end
  end

  describe "#any_write_access?" do
    it "is true when the user can change the provider or its children" do
      provider = create(:provider)

      expect(described_class.new(reg, provider).any_write_access?).to be true
      expect(described_class.new(mr, create(:provider, :accredited)).any_write_access?).to be true
      expect(described_class.new(mr, provider).any_write_access?).to be true
      expect(described_class.new(bat, provider).any_write_access?).to be true
      expect(described_class.new(reg, create(:provider, :archived)).any_write_access?).to be true
    end

    it "is false for roles that can only read" do
      provider = create(:provider)

      expect(described_class.new(ro, provider).any_write_access?).to be false
      expect(described_class.new(api_user, provider).any_write_access?).to be false
      expect(described_class.new(bat, create(:provider, :accredited)).any_write_access?).to be false
    end
  end

  describe "#any_action_buttons?" do
    it "is true only when a provider-level button is available" do
      provider = create(:provider)

      expect(described_class.new(reg, provider).any_action_buttons?).to be true
      expect(described_class.new(bat, provider).any_action_buttons?).to be true
      expect(described_class.new(mr, create(:provider, :accredited)).any_action_buttons?).to be true
      expect(described_class.new(reg, create(:provider, :archived)).any_action_buttons?).to be true
    end

    it "is false for MR on an unaccredited provider, who has write access but no button" do
      provider = create(:provider)
      policy = described_class.new(mr, provider)

      expect(policy.any_action_buttons?).to be false
      expect(policy.any_write_access?).to be true
    end

    it "is false for roles that can only read" do
      provider = create(:provider)

      expect(described_class.new(ro, provider).any_action_buttons?).to be false
      expect(described_class.new(api_user, provider).any_action_buttons?).to be false
    end

    it "never offers a button to a user the page calls read-only" do
      providers = [create(:provider), create(:provider, :accredited), create(:provider, :archived)]

      [reg, mr, bat, ro, api_user].each do |user|
        providers.each do |provider|
          policy = described_class.new(user, provider)

          expect(policy.any_action_buttons? && !policy.any_write_access?).to be false
        end
      end
    end
  end

  describe "accreditation transitions" do
    it "moves edit rights from MR to BAT when the last accreditation is removed" do
      provider = create(:provider, :accredited)

      expect(described_class.new(mr, provider).edit?).to be true
      expect(described_class.new(bat, provider).edit?).to be false

      provider.accreditations.kept.each(&:discard!)
      provider.reload

      expect(described_class.new(mr, provider).edit?).to be false
      expect(described_class.new(bat, provider).edit?).to be true
    end
  end

  describe ".policy_scope" do
    let!(:provider) { create(:provider) }

    it "returns all kept providers for every internal role" do
      [reg, mr, bat, ro].each do |user|
        expect(Pundit.policy_scope(user, Provider)).to contain_exactly(provider)
      end
    end

    it "returns all kept providers for an API user" do
      expect(Pundit.policy_scope(api_user, Provider)).to contain_exactly(provider)
    end
  end
end
