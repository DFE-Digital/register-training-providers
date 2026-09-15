RSpec.describe ProviderChangeHelper, type: :helper do
  describe "#provider_field_level_history" do
    let(:provider) { create(:provider, code: "AAA") }
    let(:creator) { create(:user) }

    let(:older) do
      create(:provider_change,
             provider: provider,
             attribute_name: "code",
             value: "AAA",
             effective_on: 2.years.ago.to_date,
             status: :completed,
             creator: creator)
    end
    let(:current) do
      create(:provider_change,
             provider: provider,
             attribute_name: "code",
             value: "BBB",
             effective_on: 1.year.ago.to_date,
             status: :completed,
             creator: creator)
    end
    let(:changes) { [current, older] }

    it "returns a row per change with effective dates, creator and status" do
      rows = helper.provider_field_level_history(changes)

      expect(rows.size).to eq(2)

      current_row = rows[0]
      expect(current_row[0]).to eq("BBB")
      expect(current_row[1]).to eq(current.effective_on.to_fs(:govuk))
      expect(current_row[2]).to eq("")
      expect(current_row[3]).to eq(creator.name)
      expect(current_row[4]).to include("Active")

      older_row = rows[1]
      expect(older_row[0]).to eq("AAA")
      expect(older_row[1]).to eq(older.effective_on.to_fs(:govuk))
      expect(older_row[2]).to eq((current.effective_on - 1.day).to_fs(:govuk))
      expect(older_row[3]).to eq(creator.name)
      expect(older_row[4]).to include("Inactive")
    end

    context "when a completed change is not yet effective" do
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: 1.year.from_now.to_date,
               status: :completed)
      end
      let(:changes) { [current] }

      it "marks the change inactive" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Inactive")
      end
    end

    context "when a completed change becomes effective today" do
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: Date.current,
               status: :completed)
      end
      let(:changes) { [current] }

      it "marks the change active" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Active")
      end
    end

    context "when the active change ends today" do
      let(:older) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "AAA",
               effective_on: 1.month.ago.to_date,
               status: :completed)
      end
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: Date.current + 1.day,
               status: :completed)
      end
      let(:changes) { [current, older] }

      it "keeps the earlier change active until the next change starts" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[4]).to include("Active")
        expect(rows.first[4]).to include("Inactive")
      end
    end

    context "when the active change ended yesterday" do
      let(:older) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "AAA",
               effective_on: 1.month.ago.to_date,
               status: :completed)
      end
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: Date.current,
               status: :completed)
      end
      let(:changes) { [current, older] }

      it "marks the earlier change inactive" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[4]).to include("Inactive")
        expect(rows.first[4]).to include("Active")
      end
    end

    context "when a change is pending" do
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: 1.year.from_now.to_date,
               status: :pending)
      end
      let(:changes) { [current] }

      it "marks the change inactive" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Inactive")
      end
    end

    context "when a change has failed" do
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: 1.year.ago.to_date,
               status: :failed)
      end
      let(:changes) { [current] }

      it "marks the change as an error" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Error")
      end
    end

    context "when the creator is no longer present" do
      it "shows a deleted user placeholder" do
        change = create(:provider_change,
                        provider: provider,
                        attribute_name: "code",
                        value: "BBB",
                        effective_on: 1.year.ago.to_date,
                        status: :completed)
        change.update_column(:created_by_id, nil)

        rows = helper.provider_field_level_history([change.reload])

        expect(rows.first[3]).to eq("Deleted user")
      end
    end
  end

  describe "#display_change_date" do
    it "formats a date" do
      expect(helper.display_change_date(Date.new(2026, 9, 1))).to eq(Date.new(2026, 9, 1).to_fs(:govuk))
    end

    it "returns an empty string for a blank date" do
      expect(helper.display_change_date(nil)).to eq("")
    end
  end
end
