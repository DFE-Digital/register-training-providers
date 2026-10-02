require "rails_helper"

RSpec.describe AccreditationHelper, type: :helper do
  describe "#accreditation_summary_cards" do
    let(:provider) { create(:provider, :accredited) }
    context "with no accreditations" do
      it "returns empty array" do
        result = helper.accreditation_summary_cards([], provider)
        expect(result).to eq([])
      end
    end

    context "with accreditations" do
      let(:accreditation) do
        create(:accreditation, :current, provider:)
      end

      context "with actions (default)" do
        it "returns summary card data with actions" do
          result = helper.accreditation_summary_cards([accreditation], provider)

          expect(result.size).to eq(1)

          card = result.first
          expect(card[:title]).to eq("Accreditation #{accreditation.number}")
          expect(card[:actions]).to include(
            { href: edit_accreditation_path(accreditation, provider_id: provider.id), text: "Change" },
            { href: accreditation_delete_path(accreditation, provider_id: provider.id), text: "Delete" }
          )

          rows = card[:rows]
          expect(rows.size).to eq(2)
          expect(rows[0][:key][:text]).to eq("Accredited provider number")
          expect(rows[0][:value][:text]).to eq(accreditation.number)
          expect(rows[1][:key][:text]).to eq("Accreditation dates")
        end
      end

      context "without actions" do
        it "returns summary card data without actions" do
          result = helper.accreditation_summary_cards([accreditation], provider, include_actions: false)

          expect(result.size).to eq(1)

          card = result.first
          expect(card[:title]).to eq("Accreditation #{accreditation.number}")
          expect(card).not_to have_key(:actions)

          rows = card[:rows]
          expect(rows.size).to eq(2)
          expect(rows[0][:key][:text]).to eq("Accredited provider number")
          expect(rows[0][:value][:text]).to eq(accreditation.number)
          expect(rows[1][:key][:text]).to eq("Accreditation dates")
        end
      end

      it "handles accreditations without end date" do
        accreditation.update!(end_date: nil)
        result = helper.accreditation_summary_cards([accreditation], provider)
        card = result.first
        dates_row = card[:rows].find { |row| row[:key][:text] == "Accreditation dates" }
        dates_html = dates_row[:value][:text]
        expect(dates_html).to include("Not entered")
      end
    end
  end

  describe "#accreditation_history_rows" do
    let(:provider) { create(:provider, with_accreditations: false) }

    def tag_text(row)
      Nokogiri::HTML.fragment(row.last).text
    end

    it "marks each accreditation active or inactive by its dates" do
      create(:accreditation, provider: provider, number: "1001", start_date: 2.years.ago.to_date, end_date: 2.days.ago.to_date)
      create(:accreditation, provider: provider, number: "1002", start_date: Date.current, end_date: 1.year.from_now.to_date)
      create(:accreditation, provider: provider, number: "1003", start_date: 1.year.ago.to_date, end_date: Date.current)
      create(:accreditation, provider: provider, number: "1004", start_date: 1.year.ago.to_date, end_date: nil)
      create(:accreditation, provider: provider, number: "1005", start_date: 1.year.from_now.to_date, end_date: 2.years.from_now.to_date)

      numbers_and_tags = helper.accreditation_history_rows(provider.reload).map do |row|
        [row.first, tag_text(row)]
      end

      expect(numbers_and_tags).to eq([
        %w[1005 Inactive], %w[1002 Active], %w[1004 Active], %w[1003 Active], %w[1001 Inactive],
      ])
    end

    it "renders 'Not entered' when the end date is missing" do
      create(:accreditation, provider: provider, number: "1001", start_date: 1.year.ago.to_date, end_date: nil)

      rows = helper.accreditation_history_rows(provider.reload)

      expect(rows.first.third).to eq("Not entered")
    end
  end
end
