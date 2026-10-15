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

  describe "#provider_field_level_history with status changes" do
    let(:provider) { create(:provider, *provider_traits) }
    let(:provider_traits) { [:archived] }
    let(:creator) { create(:user) }

    let(:baseline) do
      create(:provider_change,
             :baseline,
             provider: provider,
             attribute_name: "status",
             value: { "status" => "active" },
             effective_on: 2.years.ago.to_date)
    end
    let(:archive_change) do
      create(:provider_change,
             provider: provider,
             attribute_name: "status",
             value: { "status" => "archived" },
             effective_on: 1.year.ago.to_date,
             status: :completed,
             creator: creator)
    end

    it "renders the status label for a status change" do
      row = helper.provider_field_level_history([archive_change]).first

      expect(row[0]).to eq("Archived")
      expect(row[4]).to eq(creator.name)
      expect(row[5]).to include("Current")
    end

    context "when the status change captured reasons" do
      let(:inactive_change) do
        create(:provider_change,
               :status_change,
               provider: provider,
               value: { "status" => "inactive",
                        "reason_ids" => %w[no_current_cohorts other],
                        "other_reason" => "Lost the building" },
               effective_on: 1.month.ago.to_date,
               status: :completed,
               creator: creator)
      end

      it "renders the captured reasons in the second column" do
        row = helper.provider_field_level_history([inactive_change]).first

        expect(row[1]).to eq("No current cohorts, Lost the building")
      end

      it "keeps every cell aligned with the header columns it declares" do
        header = ["Provider status", "Reason", "Start date", "End date", "Changed by", "Current"]
        # `provider_changes.history` supplies changes latest-first, so the
        # newer inactive change precedes the older baseline. Feeding them
        # oldest-first makes the end-date clamp mask `change_period_end`.
        rows = helper.provider_field_level_history([inactive_change, baseline])

        rows.each { |row| expect(row.size).to eq(header.size) }

        inactive_row = rows[0]
        expect(inactive_row[0]).to eq("Inactive") # Provider status value
        expect(inactive_row[1]).to eq("No current cohorts, Lost the building") # Reason
        expect(inactive_row[2]).to eq(inactive_change.effective_on.to_fs(:govuk)) # Start date
        expect(inactive_row[3]).to eq("") # Latest change, so no end date
        expect(inactive_row[4]).to eq(creator.name) # Changed by
        expect(inactive_row[5]).to include("govuk-tag") # Status tag

        baseline_row = rows[1]
        # The previous status period ends the day before the newer change; the
        # value comes from `change_period_end`, not the same-start clamp.
        expect(baseline_row[3]).to eq((inactive_change.effective_on - 1.day).to_fs(:govuk))
      end

      it "leaves the reason column blank for changes without reasons" do
        row = helper.provider_field_level_history([archive_change]).first

        expect(row[1]).to eq("")
      end
    end

    context "when a system change has no creator" do
      let(:system_change) do
        create(:provider_change,
               :status_change,
               provider: provider,
               value: { "status" => "archived" },
               effective_on: 1.year.ago.to_date,
               status: :completed,
               source: :system,
               creator: nil)
      end

      it "credits the system rather than a deleted user" do
        row = helper.provider_field_level_history([system_change]).first

        expect(row[4]).to eq("System")
      end
    end

    context "when the provider currently holds a different status" do
      let(:non_archive_change) do
        create(:provider_change,
               provider: provider,
               attribute_name: "status",
               value: { "status" => "inactive" },
               effective_on: 1.year.ago.to_date,
               status: :completed,
               creator: creator)
      end

      it "marks the change as superseded" do
        row = helper.provider_field_level_history([non_archive_change]).first

        expect(row[5]).to include("Superseded")
      end
    end

    context "when a status change is scheduled for the future" do
      let(:scheduled_change) do
        create(:provider_change,
               :status_change,
               provider: provider,
               value: { "status" => "active" },
               effective_on: 1.week.from_now.to_date,
               status: :pending,
               creator: creator)
      end

      it "marks the change as scheduled rather than superseded" do
        row = helper.provider_field_level_history([scheduled_change]).first

        expect(row[5]).to include("Scheduled")
        expect(row[5]).not_to include("Inactive")
      end
    end

    it "credits the baseline with the status the provider held" do
      row = helper.provider_field_level_history([archive_change, baseline]).last

      expect(row[0]).to eq("Active")
    end
  end

  describe "#status_reason_legend" do
    it "asks the off-board wording when off-boarding" do
      expect(helper.status_reason_legend("offboarded")).to eq("Why was the provider offboarded?")
    end

    it "asks the inactive wording otherwise" do
      expect(helper.status_reason_legend("inactive")).to eq("Why did the provider become inactive?")
    end
  end

  describe "#status_effective_date_legend" do
    it "uses the off-board wording when off-boarding" do
      expect(helper.status_effective_date_legend("offboarded")).to eq("When was the provider offboarded?")
    end

    it "names the status being adopted" do
      expect(helper.status_effective_date_legend("active")).to eq("When did the provider become active?")
      expect(helper.status_effective_date_legend("inactive")).to eq("When did the provider become inactive?")
    end
  end

  describe "#status_effective_date_hint" do
    it "names the earliest date the wizard will accept" do
      provider = build_stubbed(:provider, onboarded_at: Date.new(2025, 3, 1), first_active_at: nil)

      expect(helper.status_effective_date_hint(provider))
        .to eq("For example, 31 7 2026. The provider has existed since 1 March 2025, so the date cannot be earlier.")
    end

    it "falls back to the example when the provider has no known start date" do
      provider = build_stubbed(:provider, onboarded_at: nil, first_active_at: nil)

      expect(helper.status_effective_date_hint(provider)).to eq("For example, 31 7 2026")
    end
  end
end
