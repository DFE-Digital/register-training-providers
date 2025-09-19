require "rails_helper"

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

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name).with_message("Enter first name") }
    it { is_expected.to validate_presence_of(:last_name).with_message("Enter last name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter email address") }

    context "when email is unique" do
      it "is valid with a unique email" do
        expect(user).to be_valid
      end
    end

    context "when email is not unique" do
      let(:another_user) { build(:user, email: user.email) }

      it "is not valid with a duplicate email" do
        expect(another_user).not_to be_valid
        expect(another_user.errors[:email]).to include("Email address already in use")
      end
    end

    context "when email format is valid" do
      let(:user) { build(:user, email: "email@#{hostname}") }

      ["education.gov.uk", "good.education.gov.uk"].each do |hostname|
        context "valid hostname" do
          let(:hostname) { hostname }
          it "is valid with a valid email format" do
            expect(user).to be_valid
          end
        end
      end

      context "invalid hostname" do
        let(:hostname) { "badeducation.gov.uk" }
        it "is not valid email" do
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include(
            "Enter a Department for Education email address in the correct format, like name@education.gov.uk"
          )
        end
      end
    end

    context "when email format is invalid" do
      let(:user) { build(:user, email: "invalid") }

      it "is not valid with an invalid email format" do
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include(
          "Enter a Department for Education email address in the correct format, like name@education.gov.uk"
        )
      end
    end
  end

  describe "scopes" do
    describe ".order_by_first_then_last_name" do
      let!(:albert_einstein)   { create(:user, first_name: "Albert", last_name: "Einstein") }
      let!(:marie_curie)       { create(:user, first_name: "Marie", last_name: "Curie") }
      let!(:isaac_newton)      { create(:user, first_name: "Isaac", last_name: "Newton") }
      let!(:albert_schweitzer) { create(:user, first_name: "Albert", last_name: "Schweitzer") }

      subject { described_class.order_by_first_then_last_name }

      it "returns users ordered by first_name, then last_name ascending" do
        expect(subject).to eq([
          albert_einstein,
          albert_schweitzer,
          isaac_newton,
          marie_curie
        ])
      end
    end
  end

  include_examples "a model that saves as temporary", :check_your_answers do
    let(:valid_attributes) do
      {
        first_name: "Test",
        last_name: "User",
        email: "test@education.gov.uk"
      }
    end
  end

  describe "#load_temporary" do
    let(:user) { create(:user) }

    before do
      stub_const("DummyModel", Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :uuid, :string
        attribute :foo, :string
        attribute :bar, :integer

        def ==(other)
          other.is_a?(DummyModel) && foo == other.foo && bar == other.bar
        end

        def self.find_by(uuid:)
        end
      end)
    end

    context "when a valid temporary record exists" do
      let!(:temp_record) do
        create(:temporary_record,
               creator: user,
               record_type: "DummyModel",
               data: { "foo" => "bar", "bar" => 123 },
               expires_at: 1.hour.from_now)
      end

      it "rehydrates and returns the temporary record" do
        result = user.load_temporary(DummyModel, purpose: :check_your_answers)

        expect(result).to be_a(DummyModel)
        expect(result).to have_attributes(foo: "bar", bar: 123)
      end

      context "when reset is true" do
        it "deletes existing temporary record and returns a fresh model instance" do
          expect(user.temporary_records.count).to eq(1)

          result = user.load_temporary(DummyModel, purpose: :check_your_answers, reset: true)

          expect(result).to be_a(DummyModel)
          expect(result).to have_attributes(foo: nil, bar: nil)
          expect(user.temporary_records.reload.count).to eq(0)
        end
      end
    end

    context "when the temporary record is expired" do
      let!(:temp_record) do
        create(:temporary_record,
               creator: user,
               record_type: "DummyModel",
               data: { "foo" => "bar" },
               expires_at: 2.hours.ago)
      end

      it "returns a new instance of the model" do
        result = user.load_temporary(DummyModel, purpose: :check_your_answers)

        expect(result).to be_a(DummyModel)
        expect(result).to have_attributes(foo: nil, bar: nil)
      end
    end

    context "when no temporary record exists" do
      it "returns a new instance of the model" do
        result = user.load_temporary(DummyModel, purpose: :check_your_answers)

        expect(result).to be_a(DummyModel)
        expect(result).to have_attributes(foo: nil, bar: nil)
      end
    end

    context "when id is provided" do
      let!(:temp_record) do
        create(:temporary_record,
               creator: user,
               record_type: "DummyModel",
               purpose: :check_your_answers,
               data: { "foo" => "temp_value", "bar" => 456 },
               expires_at: 1.hour.from_now)
      end

      before do
        allow(DummyModel).to receive(:find).with("00000000-0000-0000-0000-000000000042").and_return(
          DummyModel.new.tap do |model|
            model.foo = "existing_value"
            model.bar = 999
            model.id = "00000000-0000-0000-0000-000000000042"
          end
        )
      end

      it "finds the existing record and merges temporary data into it" do
        result = user.load_temporary(DummyModel, purpose: :check_your_answers, id: "00000000-0000-0000-0000-000000000042")

        expect(DummyModel).to have_received(:find_by).with(uuid: "00000000-0000-0000-0000-000000000042")
        expect(result).to be_a(DummyModel)
        expect(result.foo).to eq("temp_value")
        expect(result.bar).to eq(456)
        expect(result.id).to eq("00000000-0000-0000-0000-000000000042")
      end

      context "when no temporary record exists for the purpose" do
        let!(:temp_record) { nil }

        it "returns the found record without any merging" do
          result = user.load_temporary(DummyModel, purpose: :check_your_answers, id: "00000000-0000-0000-0000-000000000042")

          expect(DummyModel).to have_received(:find_by).with(uuid: "00000000-0000-0000-0000-000000000042")
          expect(result).to be_a(DummyModel)
          expect(result.foo).to eq("existing_value")
          expect(result.bar).to eq(999)
          expect(result.id).to eq("00000000-0000-0000-0000-000000000042")
        end
      end
    end
  end

  describe "#clear_temporary" do
    let(:user) { create(:user) }

    before do
      stub_const("DummyModel", Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :foo, :string
        attribute :bar, :integer

        def ==(other)
          other.is_a?(DummyModel) && foo == other.foo && bar == other.bar
        end
      end)
    end

    context "when a valid temporary record exists" do
      let!(:temp_record) do
        create(:temporary_record,
               creator: user,
               record_type: "DummyModel",
               data: { "foo" => "bar", "bar" => 123 },
               expires_at: 1.hour.from_now)
      end

      it "deletes existing temporary record and returns a fresh model instance" do
        expect(user.temporary_records.count).to eq(1)

        user.clear_temporary(DummyModel, purpose: :check_your_answers)

        expect(user.temporary_records.reload.count).to eq(0)
      end
    end
  end

  describe "#name" do
    let(:user) { create(:user, first_name: "John", last_name: "Doe") }

    it "returns full name when unchanged" do
      expect(user.name).to eq "John Doe"
    end

    it "returns original name when changed but not saved" do
      user.first_name = "Jane"
      expect(user.name).to eq "John Doe"

      user.last_name = "Smith"
      expect(user.name).to eq "John Doe"
    end

    it "returns new name after saving" do
      user.update!(first_name: "Jane", last_name: "Smith")
      expect(user.name).to eq "Jane Smith"
    end

    it "handles new records with changes" do
      new_user = build(:user, first_name: "Alice", last_name: "Wonder")
      new_user.first_name = "Alicia"
      expect(new_user.name).to eq "Alicia Wonder"
    end
  end
end
