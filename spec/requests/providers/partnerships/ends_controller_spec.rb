require "rails_helper"

RSpec.describe "Ending a partnership", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :school, operating_name: "Partner College") }
  let!(:partnership) do
    create(:partnership, accredited_provider: provider, provider: partner, duration: 1.year.ago..)
  end

  describe "GET the confirmation" do
    it "asks the user to confirm" do
      get provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("End partnership with #{partner.operating_name}?")
      expect(response.body).to include("will end all partnership types today")
      expect(response.body).to include("historic partnerships")
    end
  end

  describe "PATCH the confirmation" do
    it "ends the partnership today and moves it to history" do
      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:success]).to eq("Partnership with #{partner.operating_name} ended")

      partnership.reload
      expect(partnership.duration.end).to eq(Time.zone.today)
      expect(Partnership.ended).to include(partnership)
      expect(Partnership.current_or_scheduled).not_to include(partnership)
    end

    it "refuses a partnership that starts today, which is deleted instead" do
      partnership.update!(duration: Time.zone.today..)

      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to eq("The partnership could not be ended. " \
                                  "Check it has started and has not already ended.")
      expect(partnership.reload.duration.end).not_to be_a(Date)
    end
  end

  describe "a partnership that has already ended" do
    before { partnership.update!(duration: 1.year.ago...1.month.ago) }

    it "does not offer a confirmation" do
      get provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to eq("The partnership could not be ended. " \
                                  "Check it has started and has not already ended.")
    end

    it "is not ended a second time by a repeated submission" do
      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to eq("The partnership could not be ended. " \
                                  "Check it has started and has not already ended.")
      expect(partnership.reload.duration.end).to eq(1.month.ago.to_date)
    end
  end

  describe "a partnership that has not started yet" do
    before { partnership.update!(duration: 1.month.from_now..) }

    it "does not offer a confirmation" do
      get provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to be_present
    end

    it "is not ended" do
      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to be_present
      expect(partnership.reload.duration.end).not_to be_a(Date)
    end
  end

  describe "a repeated submission" do
    it "ends the partnership once and redirects instead of failing" do
      patch provider_partnership_end_path(partnership, provider_id: provider.id)
      ended_duration = partnership.reload.duration

      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:alert]).to be_present
      expect(partnership.reload.duration).to eq(ended_duration)
    end
  end

  describe "the training partner's side of the partnership" do
    it "names the accredited provider in the confirmation and the flash" do
      get provider_partnership_end_path(partnership, provider_id: partner.id)

      expect(response.body).to include("End partnership with #{provider.operating_name}?")

      patch provider_partnership_end_path(partnership, provider_id: partner.id)

      expect(flash[:success]).to eq("Partnership with #{provider.operating_name} ended")
      expect(partnership.reload.duration.end).to eq(Time.zone.today)
    end
  end

  describe "the rate limit" do
    it "allows 3 submissions within 3 minutes but blocks the 4th" do
      Timecop.freeze(Time.zone.now) do
        3.times do
          patch provider_partnership_end_path(partnership, provider_id: provider.id)
          expect(response).to have_http_status(:redirect)
        end

        expect(Rails.logger).to receive(:warn).with(
          event: "too_many_requests",
          user_id: user.id,
          controller: "Providers::Partnerships::EndsController",
          action: "update",
          path: "/providers/#{provider.id}/partnerships/#{partnership.id}/end",
        )

        patch provider_partnership_end_path(partnership, provider_id: provider.id)

        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe "the provider in the route" do
    it "cannot be an archived provider" do
      provider.update!(archived_at: Time.zone.now)

      get provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "still allows ending when only the training partner is archived" do
      partner.update!(archived_at: Time.zone.now)

      patch provider_partnership_end_path(partnership, provider_id: provider.id)

      expect(flash[:success]).to eq("Partnership with #{partner.operating_name} ended")
      expect(partnership.reload.duration.end).to eq(Time.zone.today)
    end
  end

  describe "a partnership belonging to another provider" do
    let(:other_provider) { create(:provider, :accredited) }
    let(:other_partnership) do
      create(:partnership, accredited_provider: other_provider, provider: partner, duration: 1.year.ago..)
    end

    it "cannot be ended from this provider" do
      get provider_partnership_end_path(other_partnership, provider_id: provider.id)

      expect(response).to have_http_status(:not_found)
    end
  end
end
