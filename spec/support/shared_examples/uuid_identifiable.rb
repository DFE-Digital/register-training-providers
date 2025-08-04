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
end
