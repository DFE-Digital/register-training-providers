RSpec.shared_examples "uuid identifiable" do
  it "generates a uuid before validation if missing" do
    subject.uuid = nil
    subject.valid?
    expect(subject.uuid).to match(/\A[0-9a-f\-]{36}\z/)
  end

  it "does not overwrite an existing uuid" do
    custom_uuid = SecureRandom.uuid
    subject.uuid = custom_uuid
    subject.valid?
    expect(subject.uuid).to eq(custom_uuid)
  end

  it "uses uuid as to_param" do
    uuid = SecureRandom.uuid
    subject.uuid = uuid
    subject.valid?
    expect(subject.to_param).to eq(uuid)
  end

  describe ".find" do
    it "finds record by UUID when given a UUID" do
      record = subject
      record.save!
      
      found_record = described_class.find(record.uuid)
      expect(found_record).to eq(record)
    end

    it "finds record by integer ID when given an integer" do
      record = subject
      record.save!
      
      found_record = described_class.find(record.id)
      expect(found_record).to eq(record)
    end

    it "raises RecordNotFound when UUID doesn't exist" do
      non_existent_uuid = SecureRandom.uuid
      
      expect { described_class.find(non_existent_uuid) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound when integer ID doesn't exist" do
      expect { described_class.find(999999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
