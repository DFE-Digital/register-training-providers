require "rails_helper"

RSpec.describe "Role restrictions", type: :request do
  include DfESignInUserHelper

  let(:accredited_provider) { create(:provider, :accredited) }
  let(:unaccredited_provider) { create(:provider) }
  let(:inactive_provider) { create(:provider, :with_current_inactive_period) }
  let(:inactive_accredited_provider) { create(:provider, :accredited, :with_current_inactive_period) }

  describe "provider changes" do
    it "denies MR on an unaccredited provider" do
      sign_in_as(create(:user, :mr))

      get provider_change_step_path(provider_id: unaccredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT on an accredited provider" do
      sign_in_as(create(:user, :bat))

      get provider_change_step_path(provider_id: accredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO on any provider" do
      sign_in_as(create(:user, :ro))

      get provider_change_step_path(provider_id: accredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:forbidden)
    end

    it "permits REG on both providers" do
      sign_in_as(create(:user, :reg))

      get provider_change_step_path(provider_id: accredited_provider.id, field: "operating_name", step: "effective-date")
      expect(response).to have_http_status(:ok)

      get provider_change_step_path(provider_id: unaccredited_provider.id, field: "operating_name", step: "effective-date")
      expect(response).to have_http_status(:ok)
    end

    it "permits MR on an accredited provider" do
      sign_in_as(create(:user, :mr))

      get provider_change_step_path(provider_id: accredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:ok)
    end

    it "permits BAT on an unaccredited provider" do
      sign_in_as(create(:user, :bat))

      get provider_change_step_path(provider_id: unaccredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "provider lifecycle" do
    it "denies RO archiving" do
      sign_in_as(create(:user, :ro))

      put provider_archive_path(inactive_provider)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies MR archiving an unaccredited provider" do
      sign_in_as(create(:user, :mr))

      put provider_archive_path(inactive_provider)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT archiving an accredited provider" do
      sign_in_as(create(:user, :bat))

      put provider_archive_path(inactive_accredited_provider)

      expect(response).to have_http_status(:forbidden)
    end

    it "permits BAT archiving an inactive unaccredited provider" do
      sign_in_as(create(:user, :bat))

      put provider_archive_path(inactive_provider)

      expect(response).to have_http_status(:redirect)
    end

    it "denies MR deleting an archived provider" do
      sign_in_as(create(:user, :mr))

      delete provider_delete_path(create(:provider, :archived))

      expect(response).to have_http_status(:forbidden)
    end

    it "permits REG deleting an archived provider" do
      archived_provider = create(:provider, :archived)
      sign_in_as(create(:user, :reg))

      delete provider_delete_path(archived_provider)

      expect(response).to have_http_status(:redirect)
      expect(archived_provider.reload).to be_discarded
    end

    it "denies RO restoring an archived provider" do
      sign_in_as(create(:user, :ro))

      put provider_restore_path(create(:provider, :archived))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "accreditation" do
    it "denies BAT creating an accreditation" do
      sign_in_as(create(:user, :bat))

      post accreditations_path(provider_id: unaccredited_provider.id), params: { accreditation: { number: "1234" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO creating an accreditation" do
      sign_in_as(create(:user, :ro))

      post accreditations_path(provider_id: unaccredited_provider.id), params: { accreditation: { number: "1234" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR creating an accreditation on an unaccredited provider" do
      mr = create(:user, :mr)
      sign_in_as(mr)

      post accreditations_path(provider_id: unaccredited_provider.id),
           params: {
             accreditation: {
               number: "1234",
               "start_date(3i)" => "1",
               "start_date(2i)" => "1",
               "start_date(1i)" => "2024",
             },
           }

      expect(response).to have_http_status(:redirect)
      expect(
        mr.temporary_records.where(
          record_type: "AccreditationForm",
          purpose: "create_accreditation_#{unaccredited_provider.id}",
        ),
      ).to exist
    end

    it "permits MR opening the new accreditation form" do
      sign_in_as(create(:user, :mr))

      get new_accreditation_path(provider_id: unaccredited_provider.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "partnerships" do
    it "denies BAT creating a partnership" do
      sign_in_as(create(:user, :bat))

      post provider_partnership_find_path(unaccredited_provider), params: { find: { partner_id: accredited_provider.id } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO creating a partnership" do
      sign_in_as(create(:user, :ro))

      post provider_partnership_find_path(unaccredited_provider), params: { find: { partner_id: accredited_provider.id } }

      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR creating a partnership on an unaccredited provider" do
      sign_in_as(create(:user, :mr))

      post provider_partnership_find_path(unaccredited_provider), params: { find: { partner_id: accredited_provider.id } }

      expect(response).to have_http_status(:redirect)
    end

    it "permits MR opening the new partnership form" do
      sign_in_as(create(:user, :mr))

      get provider_new_partnership_find_path(unaccredited_provider)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "associated records" do
    it "denies MR adding a contact to an unaccredited provider" do
      sign_in_as(create(:user, :mr))

      post provider_contacts_path(unaccredited_provider),
           params: { contact: { first_name: "A", provider_id: unaccredited_provider.id } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT adding a contact to an accredited provider" do
      sign_in_as(create(:user, :bat))

      post provider_contacts_path(accredited_provider),
           params: { contact: { first_name: "A", provider_id: accredited_provider.id } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO adding an address" do
      sign_in_as(create(:user, :ro))

      post provider_addresses_path(unaccredited_provider), params: { address: { address_line_1: "A" } }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "delete confirmations" do
    it "denies a REG opening the delete confirmation for a system admin" do
      sign_in_as(create(:user, :reg))
      system_admin = create(:user, :reg, system_admin: true)

      get user_delete_path(system_admin)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening an accreditation delete confirmation" do
      accreditation = create(:accreditation, :current, provider: accredited_provider)
      sign_in_as(create(:user, :ro))

      get accreditation_delete_path(accreditation, provider_id: accredited_provider.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening a partnership delete confirmation" do
      partnership = create(:partnership, provider: unaccredited_provider)
      sign_in_as(create(:user, :ro))

      get provider_partnership_delete_path(partnership, provider_id: unaccredited_provider.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening a contact delete confirmation" do
      contact = create(:contact, provider: unaccredited_provider)
      sign_in_as(create(:user, :ro))

      get provider_contact_delete_path(contact, provider_id: unaccredited_provider.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening an address delete confirmation" do
      address = create(:address, provider: unaccredited_provider)
      sign_in_as(create(:user, :ro))

      get provider_address_delete_path(address, provider_id: unaccredited_provider.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening a provider delete confirmation" do
      sign_in_as(create(:user, :ro))

      get provider_delete_path(create(:provider, :archived))

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening a provider archive confirmation" do
      sign_in_as(create(:user, :ro))

      get provider_archive_path(unaccredited_provider)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO opening a provider restore confirmation" do
      sign_in_as(create(:user, :ro))

      get provider_restore_path(create(:provider, :archived))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "administration" do
    it "denies MR creating a user" do
      sign_in_as(create(:user, :mr))

      post users_path, params: { user: { first_name: "A", last_name: "B", email: "role.restriction@education.gov.uk" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies RO creating an API client" do
      sign_in_as(create(:user, :ro))

      post api_clients_path, params: { api_client: { name: "Test" } }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "API user" do
    let(:api_user) { create(:user, api_user: true) }

    it "permits reading provider information" do
      sign_in_as(api_user)

      [providers_path,
       provider_path(unaccredited_provider),
       provider_accreditations_path(unaccredited_provider),
       provider_addresses_path(unaccredited_provider),
       provider_contacts_path(unaccredited_provider),
       provider_partnerships_path(unaccredited_provider)].each do |path|
        get path

        expect(response).to have_http_status(:ok)
      end
    end

    it "denies creating a provider" do
      sign_in_as(api_user)

      post new_provider_is_the_provider_accredited_path, params: { provider: { accreditation_status: "unaccredited" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies changing a provider" do
      sign_in_as(api_user)

      get provider_change_step_path(provider_id: unaccredited_provider.id, field: "operating_name", step: "effective-date")

      expect(response).to have_http_status(:forbidden)
    end

    it "denies archiving, restoring and deleting providers" do
      archived_provider = create(:provider, :archived)

      sign_in_as(api_user)

      put provider_archive_path(unaccredited_provider)
      expect(response).to have_http_status(:forbidden)

      put provider_restore_path(archived_provider)
      expect(response).to have_http_status(:forbidden)

      delete provider_delete_path(archived_provider)
      expect(response).to have_http_status(:forbidden)
    end

    it "denies creating accreditations and partnerships" do
      sign_in_as(api_user)

      post accreditations_path(provider_id: unaccredited_provider.id), params: { accreditation: { number: "1234" } }
      expect(response).to have_http_status(:forbidden)

      post provider_partnership_find_path(unaccredited_provider), params: { find: { partner_id: accredited_provider.id } }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies creating contacts and addresses" do
      sign_in_as(api_user)

      post provider_contacts_path(unaccredited_provider),
           params: { contact: { first_name: "A", provider_id: unaccredited_provider.id } }
      expect(response).to have_http_status(:forbidden)

      post provider_addresses_path(unaccredited_provider), params: { address: { address_line_1: "A" } }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies administering users" do
      sign_in_as(api_user)

      post users_path, params: { user: { first_name: "A", last_name: "B", email: "api.user.restriction@education.gov.uk" } }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
