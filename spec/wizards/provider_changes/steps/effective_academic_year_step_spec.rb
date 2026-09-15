RSpec.describe ProviderChanges::Steps::EffectiveAcademicYearStep do
  subject(:step) { described_class.new(wizard:, effective_on:) }

  let(:wizard) { double(state_store:, provider:) }
  let(:state_store) { double(code:) }
  let(:code) { "ABC" }
  let(:provider) { create(:provider) }
  let(:effective_on) { following_academic_year_start_date }

  let(:next_academic_year_start_date) do
    AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.next_academic_year)
  end
  let(:following_academic_year_start_date) do
    AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.following_academic_year)
  end

  describe ".permitted_params" do
    it "permits effective_on" do
      expect(described_class.permitted_params).to eq(%i[effective_on])
    end
  end

  describe "validations" do
    it "requires an offered effective date" do
      step = described_class.new(wizard: wizard, effective_on: nil)

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Select an academic year")
    end

    it "accepts the next academic year start date" do
      expect(described_class.new(wizard: wizard, effective_on: next_academic_year_start_date)).to be_valid
    end

    it "accepts the following academic year start date" do
      expect(described_class.new(wizard: wizard, effective_on: following_academic_year_start_date)).to be_valid
    end

    it "rejects a date that is not an offered academic year" do
      step = described_class.new(wizard: wizard, effective_on: Date.new(2026, 9, 1))

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Select an academic year")
    end
  end

  describe "availability" do
    before do
      allow(ProviderCodeTakenService).to receive(:call).and_return(false)
    end

    it "checks availability using the stored code and the effective date" do
      expect(ProviderCodeTakenService)
        .to receive(:call)
        .with(
          code:,
          effective_on:,
          provider:
        )
        .and_return(false)

      expect(step).to be_valid
    end

    it "rejects an effective date that is already taken" do
      allow(ProviderCodeTakenService)
        .to receive(:call)
        .with(
          code:,
          effective_on:,
          provider:
        )
        .and_return(true)

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Select another academic year")
    end

    it "does not check availability when no code has been entered" do
      no_code_wizard = double(state_store: double(code: nil), provider: provider)
      step = described_class.new(wizard: no_code_wizard, effective_on: effective_on)

      expect(ProviderCodeTakenService).not_to receive(:call)
      expect(step).to be_valid
    end

    it "does not check availability when the effective date is missing" do
      step = described_class.new(wizard: wizard, effective_on: nil)

      expect(ProviderCodeTakenService).not_to receive(:call)
      expect(step).not_to be_valid
    end

    it "does not check availability when the provider already holds a following-year claim" do
      create(
        :provider_change,
        provider: provider,
        attribute_name: "code",
        value: code,
        effective_on: following_academic_year_start_date
      )

      expect(ProviderCodeTakenService).not_to receive(:call)
      expect(step).to be_valid
    end

    it "still checks availability when the provider's own claim is not the following year" do
      create(
        :provider_change,
        provider: provider,
        attribute_name: "code",
        value: code,
        effective_on: next_academic_year_start_date
      )

      expect(ProviderCodeTakenService).to receive(:call).and_return(false)

      described_class.new(wizard: wizard, effective_on: next_academic_year_start_date).valid?
    end
  end

  describe "academic year helpers" do
    let(:step) { described_class.new(wizard:) }

    it "returns the next academic year label" do
      expect(step.next_academic_year_label)
        .to eq(
          "#{AcademicYearCalculator.next_academic_year} to #{AcademicYearCalculator.next_academic_year + 1} academic year"
        )
    end

    it "returns the following academic year label" do
      expect(step.following_academic_year_label)
        .to eq(
          "#{AcademicYearCalculator.following_academic_year} to #{AcademicYearCalculator.following_academic_year + 1} academic year"
        )
    end

    it "returns the next academic year start date" do
      expect(step.next_academic_year_start_date)
        .to eq(AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.next_academic_year))
    end

    it "returns the following academic year start date" do
      expect(step.following_academic_year_start_date)
        .to eq(AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.following_academic_year))
    end
  end
end
