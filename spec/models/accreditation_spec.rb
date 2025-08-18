require "rails_helper"

RSpec.describe Accreditation, type: :model do
  let(:accreditation) { create(:accreditation) }
  subject { accreditation }

  it_behaves_like "uuid identifiable"

  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      accreditation = build(:accreditation)
      expect(accreditation).to be_valid
    end

    it "requires a number" do
      accreditation = build(:accreditation, number: nil)
      expect(accreditation).not_to be_valid
      expect(accreditation.errors[:number]).to include("can't be blank")
    end

    it "requires a start_date" do
      accreditation = build(:accreditation, start_date: nil)
      expect(accreditation).not_to be_valid
      expect(accreditation.errors[:start_date]).to include("can't be blank")
    end
  end

  describe "scopes" do
    let(:provider) { create(:provider) }
    let!(:current_accreditation) { create(:accreditation, :current, provider: provider) }
    let!(:expired_accreditation) { create(:accreditation, :expired, provider: provider) }
    let!(:future_accreditation) { create(:accreditation, :future, provider: provider) }

    describe ".current" do
      it "returns only current accreditations" do
        expect(Accreditation.current).to contain_exactly(current_accreditation)
      end

      it "includes accreditations with no end date that have started" do
        indefinite_accreditation = create(:accreditation, :indefinite, provider: provider)
        expect(Accreditation.current).to include(indefinite_accreditation)
      end
    end

    describe ".order_by_start_date" do
      it "orders accreditations by start date" do
        accreditations = Accreditation.order_by_start_date
        expect(accreditations.first).to eq(expired_accreditation)
        expect(accreditations.last).to eq(future_accreditation)
      end
    end
  end

  describe "provider accreditation status sync" do
    it "updates provider accreditation status to accredited when current accreditation is created" do
      provider = create(:provider, :unaccredited)
      expect(provider.accreditation_status).to eq("unaccredited")

      create(:accreditation, :current, provider: provider)
      provider.reload
      expect(provider.accreditation_status).to eq("accredited")
    end

    it "updates provider accreditation status to unaccredited when last current accreditation is destroyed" do
      provider = create(:provider, :unaccredited)
      accreditation = create(:accreditation, :current, provider: provider)
      provider.reload
      expect(provider.accreditation_status).to eq("accredited")

      accreditation.destroy
      provider.reload
      expect(provider.accreditation_status).to eq("unaccredited")
    end

    it "handles destroy callback safely when provider is deleted first" do
      provider = create(:provider, :unaccredited)
      accreditation = create(:accreditation, :current, provider: provider)
      
      # Delete the provider first
      provider.destroy
      
      # This should not raise an error
      expect { accreditation.destroy }.not_to raise_error
    end

    it "updates provider accreditation status when accreditation dates change" do
      provider = create(:provider, :unaccredited)
      accreditation = create(:accreditation, :current, provider: provider)
      provider.reload
      expect(provider.accreditation_status).to eq("accredited")

      # Make the accreditation expired by updating the end date
      accreditation.update!(end_date: 1.day.ago)
      provider.reload
      expect(provider.accreditation_status).to eq("unaccredited")
    end

    it "doesn't change status unnecessarily when provider already has correct status" do
      provider = create(:provider, :unaccredited)
      create(:accreditation, :current, provider: provider)
      provider.reload
      expect(provider.accreditation_status).to eq("accredited")
      
      # Spy on the update_column method to ensure it's not called unnecessarily
      allow(provider).to receive(:update_column)
      
      # Create another current accreditation - status should remain accredited
      create(:accreditation, :current, provider: provider)
      provider.reload
      
      expect(provider).not_to have_received(:update_column)
    end
  end
end
