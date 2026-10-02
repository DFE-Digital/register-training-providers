RSpec.describe ProviderChangeHelper, type: :helper do
  describe "#provider_field_level_history" do
    let(:provider) { create(:provider, code: "BBB") }
    let(:creator) { create(:user) }

    let(:baseline) do
      create(:provider_change,
             :baseline,
             provider: provider,
             attribute_name: "code",
             value: "AAA",
             effective_on: 3.years.ago.to_date)
    end
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
      expect(older_row[4]).to include("Inactive")
    end

    context "when a baseline is included" do
      let(:changes) { [current, baseline] }

      it "renders the value the provider held before its first change" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[0]).to eq("AAA")
        expect(rows.last[1]).to eq(baseline.effective_on.to_fs(:govuk))
        expect(rows.last[2]).to eq((current.effective_on - 1.day).to_fs(:govuk))
      end

      it "credits the person who created the provider, where the audit trail knows them" do
        creator = create(:user)
        provider.audits.find_by(action: "create").update!(user: creator)

        expect(helper.provider_field_level_history(changes).last[3]).to eq(creator.name)
      end

      it "falls back to the value itself when no creation audit has a user" do
        expect(helper.provider_field_level_history(changes).last[3]).to eq("Initial value")
      end

      context "when the provider still holds the baseline value" do
        let(:provider) { create(:provider, code: "AAA") }

        it "keeps the baseline active" do
          expect(helper.provider_field_level_history([baseline]).first[4]).to include("Active")
        end
      end
    end

    context "when a baseline and the change superseding it share an effective date" do
      let(:baseline) do
        create(:provider_change,
               :baseline,
               provider: provider,
               attribute_name: "code",
               value: "AAA",
               effective_on: Date.current)
      end
      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: Date.current,
               status: :completed)
      end
      let(:changes) { [current, baseline] }

      it "never ends a period before it starts" do
        rows = helper.provider_field_level_history(changes)

        baseline_row = rows.find { |row| row[0] == "AAA" }

        expect(baseline_row[1]).to eq(Date.current.to_fs(:govuk))
        expect(baseline_row[2]).to eq(Date.current.to_fs(:govuk))
      end
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
      let(:changes) { [current, older] }

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
      let(:changes) { [current, older] }

      it "marks the change active" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Active")
      end
    end

    context "when the active change ends today" do
      let(:provider) { create(:provider, code: "AAA") }

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
      let(:provider) { create(:provider, code: "AAA") }

      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: 1.year.from_now.to_date,
               status: :pending)
      end
      let(:changes) { [current, older] }

      it "marks the change inactive" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Inactive")
      end

      it "does not let it end the period of the value still in force" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[2]).to eq("")
        expect(rows.last[4]).to include("Active")
      end
    end

    context "when a change has failed" do
      let(:provider) { create(:provider, code: "AAA") }

      let(:current) do
        create(:provider_change,
               provider: provider,
               attribute_name: "code",
               value: "BBB",
               effective_on: 1.year.ago.to_date,
               status: :failed)
      end
      let(:changes) { [current, baseline] }

      it "marks the change as an error" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.first[4]).to include("Error")
      end

      it "leaves the value still in force marked active" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[4]).to include("Active")
      end

      it "does not let the failed change truncate the value still in force" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.last[2]).to eq("")
      end
    end

    context "when the provider has been edited outside the change wizards" do
      let(:changes) { [current, older] }

      before { provider.update_column(:code, "ZZZ") }

      it "does not call a superseded row active" do
        rows = helper.provider_field_level_history(changes)

        expect(rows.map(&:last).join).not_to include("Active")
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

    context "when a change has a blank value" do
      let(:urn_change) do
        create(:provider_change,
               provider: provider,
               attribute_name: "urn",
               value: "",
               effective_on: 1.year.ago.to_date,
               status: :completed)
      end
      let(:code_change) do
        build(:provider_change,
              provider: provider,
              attribute_name: "code",
              value: "",
              effective_on: 1.year.ago.to_date,
              status: :completed)
      end

      it "labels a blank URN as no URN recorded" do
        row = helper.provider_field_level_history([urn_change]).first

        expect(row[0]).to eq("No URN recorded")
      end

      it "keeps the default label for other blank attributes" do
        expect(helper.format_change_value(code_change)).to eq("Not entered")
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
