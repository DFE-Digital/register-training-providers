require "rails_helper"

RSpec.describe ProviderSummaryHelper, type: :helper do
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
          expect(rows).to include(
            { key: { text: "Accreditation number" }, value: { text: accreditation.number } },
            { key: { text: "Date accreditation starts" }, value: { text: accreditation.start_date.to_fs(:govuk) } },
            { key: { text: "Date accreditation ends" }, value: { text: accreditation.end_date.to_fs(:govuk) } }
          )
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
          expect(rows).to include(
            { key: { text: "Accreditation number" }, value: { text: accreditation.number } },
            { key: { text: "Date accreditation starts" }, value: { text: accreditation.start_date.to_fs(:govuk) } },
            { key: { text: "Date accreditation ends" }, value: { text: accreditation.end_date.to_fs(:govuk) } }
          )
        end
      end

      it "handles accreditations without end date" do
        accreditation.update!(end_date: nil)
        result = helper.accreditation_summary_cards([accreditation], provider)
        card = result.first
        end_date_row = card[:rows].find { |row| row[:key][:text] == "Date accreditation ends" }
        expect(end_date_row[:value]).to eq({ text: "Not entered", classes: "govuk-hint" })
      end
    end
  end
end
