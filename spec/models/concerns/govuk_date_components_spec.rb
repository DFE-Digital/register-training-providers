require "rails_helper"

RSpec.describe GovukDateComponents do
  let(:described_class_with_choice) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include GovukDateComponents

      has_date_components_with_choice :start_date

      attr_accessor :start_date_choice

      def attributes
        {
          "start_date" => start_date,
          "start_date_day" => start_date_day,
          "start_date_month" => start_date_month,
          "start_date_year" => start_date_year,
          "start_date_choice" => start_date_choice
        }
      end
    end
  end

  let(:described_class_without_choice) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include GovukDateComponents

      has_date_components :start_date

      def attributes
        {
          "start_date" => start_date,
          "start_date_day" => start_date_day,
          "start_date_month" => start_date_month,
          "start_date_year" => start_date_year
        }
      end
    end
  end

  describe ".has_date_components" do
    it "defines date attributes" do
      klass = described_class_without_choice

      expect(klass::DATE_FIELDS).to eq([:start_date])
      expect(klass::PARAM_CONVERSION).to include(
        "start_date(3i)" => "start_date_day",
        "start_date(2i)" => "start_date_month",
        "start_date(1i)" => "start_date_year"
      )
      expect(klass::CHOICE).to eq(false)
    end
  end

  describe ".has_date_components_with_choice" do
    it "defines date attributes including choice field" do
      klass = described_class_with_choice

      expect(klass::DATE_FIELDS).to eq([:start_date])
      expect(klass::PARAM_CONVERSION).to include(
        "start_date_choice" => "start_date_choice"
      )
      expect(klass::CHOICE).to eq(true)
    end
  end

  describe "#build_date_from_components (via public behaviour)" do
    let(:form) { described_class_without_choice.new }

    it "builds a valid date" do
      form.start_date_day = 17
      form.start_date_month = 6
      form.start_date_year = 2025

      form.send(:convert_date_components)

      expect(form.start_date).to eq(Date.new(2025, 6, 17))
    end

    it "returns nil for invalid date" do
      form.start_date_day = 31
      form.start_date_month = 2
      form.start_date_year = 2025

      form.send(:convert_date_components)

      expect(form.start_date).to be_nil
    end
  end

  describe "#resolve_date_from_choice" do
    let(:form) { described_class_with_choice.new }

    before do
      allow(form).to receive(:predefined_dates).and_return(
        "today" => Date.new(2026, 1, 1)
      )
    end

    it "returns predefined date when choice matches" do
      form.start_date_choice = "today"

      expect(form.resolve_date_from_choice(:start_date)).to eq(Date.new(2026, 1, 1))
    end

    it "falls back to components when choice is 'other'" do
      form.start_date_choice = "other"

      form.start_date_day = 17
      form.start_date_month = 6
      form.start_date_year = 2025

      expect(form.resolve_date_from_choice(:start_date)).to eq(Date.new(2025, 6, 17))
    end

    it "falls back to components when choice is blank" do
      form.start_date_choice = nil

      form.start_date_day = 17
      form.start_date_month = 6
      form.start_date_year = 2025

      expect(form.resolve_date_from_choice(:start_date)).to eq(Date.new(2025, 6, 17))
    end
  end

  describe "#extract_date_components_from" do
    let(:form) { described_class_without_choice.new }

    it "extracts date components from source object" do
      source = Struct.new(:start_date).new(Date.new(2025, 6, 17))

      expect(form.extract_date_components_from(source)).to eq(
        start_date: Date.new(2025, 6, 17),
        start_date_day: 17,
        start_date_month: 6,
        start_date_year: 2025
      )
    end

    it "handles nil dates" do
      source = Struct.new(:start_date).new(nil)

      expect(form.extract_date_components_from(source)).to eq(
        start_date: nil
      )
    end
  end

  describe "#serializable_hash" do
    context "without choice" do
      let(:form) { described_class_without_choice.new }

      before do
        form.start_date = Date.new(2025, 6, 17)
        form.start_date_day = 17
        form.start_date_month = 6
        form.start_date_year = 2025
      end

      it "includes date and components" do
        expect(form.serializable_hash).to include(
          "start_date" => Date.new(2025, 6, 17),
          "start_date_day" => 17,
          "start_date_month" => 6,
          "start_date_year" => 2025
        )
      end
    end

    context "with choice" do
      let(:form) { described_class_with_choice.new }

      before do
        form.start_date = Date.new(2025, 6, 17)
        form.start_date_day = 17
        form.start_date_month = 6
        form.start_date_year = 2025
        form.start_date_choice = "today"
      end

      it "includes choice field in serialization" do
        expect(form.serializable_hash).to include(
          "start_date_choice" => "today"
        )
      end
    end
  end
end
