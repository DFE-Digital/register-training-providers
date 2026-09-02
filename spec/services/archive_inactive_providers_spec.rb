RSpec.describe ArchiveInactiveProviders do
  subject { described_class.call }

  let(:active_provider) { create(:provider) }
  let(:newly_inactive_provider) { create(:provider, inactive_periods: [{ start_date: 1.year.ago, end_date: nil }]) }
  let(:old_inactive_provider) { create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }]) }

  it "should archive providers who have been inactive for more than three years" do
    expect(old_inactive_provider.archived?).to eq(false)

    subject
    old_inactive_provider.reload

    expect(old_inactive_provider.archived?).to eq(true)
  end

  it "should not archive providers who have been inactive for less than three years" do
    expect(newly_inactive_provider.archived?).to eq(false)

    subject
    newly_inactive_provider.reload

    expect(newly_inactive_provider.archived?).to eq(false)
  end

  it "should not archive providers who are active" do
    expect(active_provider.archived?).to eq(false)

    subject
    active_provider.reload

    expect(active_provider.archived?).to eq(false)
  end
end
