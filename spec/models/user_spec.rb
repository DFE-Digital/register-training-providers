require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "user is discarded" do
    before do
      user.discard!
    end

    it "the user is discarded" do
      expect(user).to be_discarded
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name).with_message("Enter first name") }
    it { is_expected.to validate_presence_of(:last_name).with_message("Enter last name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter email address") }


    context 'when email is unique' do
      it 'is valid with a unique email' do
        expect(user).to be_valid
      end
    end

    context 'when email is not unique' do
      let(:another_user) { build(:user, email: user.email) }

      it 'is not valid with a duplicate email' do
        expect(another_user).not_to be_valid
        expect(another_user.errors[:email]).to include('Email address already in use')
      end
    end

    context 'when email format is valid' do
      let(:user) { build(:user, email: "email@#{hostname}") }

      [ "education.gov.uk", "good.education.gov.uk" ].each do |hostname|
        context "valid hostname" do
          let(:hostname) { hostname }
          it 'is valid with a valid email format' do
            expect(user).to be_valid
          end
        end
      end

      context "invalid hostname" do
        let(:hostname) { "badeducation.gov.uk" }
        it 'is not valid email' do
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include(
            "Enter a Department for Education email address in the correct format, like name@education.gov.uk")
        end
      end
    end

    context 'when email format is invalid' do
      let(:user) { build(:user, email: 'invalid') }

      it 'is not valid with an invalid email format' do
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include(
          "Enter a Department for Education email address in the correct format, like name@education.gov.uk")
      end
    end
  end
end
