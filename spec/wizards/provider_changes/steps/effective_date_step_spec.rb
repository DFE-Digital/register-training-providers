RSpec.describe ProviderChanges::Steps::EffectiveDateStep do
  let(:today) { Time.zone.today }

  def build_step(day: today.day, month: today.month, year: today.year)
    described_class.new(
      "effective_on(3i)" => day.to_s,
      "effective_on(2i)" => month.to_s,
      "effective_on(1i)" => year.to_s
    )
  end

  describe ".permitted_params" do
    it "permits the date and raw GOV.UK date params" do
      expect(described_class.permitted_params)
        .to eq([:effective_on, "effective_on(3i)", "effective_on(2i)", "effective_on(1i)"])
    end
  end

  describe "validations" do
    it "accepts today" do
      expect(build_step).to be_valid
    end

    it "accepts a future date" do
      future = today + 1.month

      expect(build_step(day: future.day, month: future.month, year: future.year)).to be_valid
    end

    it "rejects a past date" do
      step = build_step(day: 31, month: 12, year: today.year - 1)

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Effective on must be today or in the future")
    end

    it "rejects a blank date" do
      step = described_class.new(
        "effective_on(3i)" => "",
        "effective_on(2i)" => "",
        "effective_on(1i)" => ""
      )

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Enter effective on")
    end

    it "rejects a missing day" do
      step = described_class.new(
        "effective_on(3i)" => "",
        "effective_on(2i)" => today.month.to_s,
        "effective_on(1i)" => today.year.to_s
      )

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Effective on must include a day")
    end

    it "rejects a 2 digit year" do
      step = described_class.new(
        "effective_on(3i)" => today.day.to_s,
        "effective_on(2i)" => today.month.to_s,
        "effective_on(1i)" => today.year.to_s.last(2)
      )

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Year must include 4 numbers")
    end

    it "rejects a date that does not exist" do
      step = described_class.new(
        "effective_on(3i)" => "31",
        "effective_on(2i)" => "2",
        "effective_on(1i)" => today.year.to_s
      )

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Effective on must be a real date")
    end
  end
end
