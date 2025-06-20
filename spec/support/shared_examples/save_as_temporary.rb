RSpec.shared_examples "a model that saves as temporary" do |purpose|
  let(:creator) { create(:user) }
  subject { described_class.new(valid_attributes) }

  describe "#save_as_temporary!" do
    context "when valid" do
      it "creates a TemporaryRecord with correct data" do
        expect {
          subject.save_as_temporary!(created_by: creator, expires_in: 1.hour, purpose: purpose)
        }.to change(TemporaryRecord, :count).by(1)

        temp = TemporaryRecord.last
        expect(temp.record_type).to eq(subject.class.name)
        expect(temp.created_by).to eq(creator.id)
        expect(temp.purpose).to eq("check_your_answers")

        valid_attributes.each do |key, value|
          expect(temp.data[key.to_s]).to eq(value)
        end

        expect(temp.expires_at).to be_within(1.minute).of(1.hour.from_now)
      end
    end

    context "when invalid" do
      it "raises ActiveRecord::RecordInvalid" do
        if subject.respond_to?(:valid?)
          allow(subject).to receive(:valid?).and_return(false)
        end

        expect {
          subject.save_as_temporary!(created_by: creator, purpose: purpose)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
