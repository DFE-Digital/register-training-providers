module ActivityItem
  class View < ApplicationComponent
    ACTIVITY_LABELS = {
      "Provider" => "Provider",
      "Address" => "Provider address",
      "Accreditation" => "Provider accreditation",
      "Contact" => "Provider contact",
      "User" => "User"
    }.freeze

    attr_reader :audit, :show_title

    def initialize(audit:, show_title: true)
      @audit = audit
      @show_title = show_title
      super()
    end

    def activity_label
      ACTIVITY_LABELS[audit.auditable_type] || audit.auditable_type
    end

    ACTION_LABELS = {
      "create" => "added",
      "update" => "updated",
      "destroy" => "deleted"
    }.freeze

    def action_text
      return archived_or_restored_action if provider_archived_or_restored?
      return discarded_or_restored_action if record_discarded_or_restored?

      ACTION_LABELS[audit.action] || audit.action
    end

    def full_description
      "#{activity_label} #{action_text}"
    end

    def user_name
      return "Deleted user" unless audit.user

      audit.user.name
    end

    def timestamp
      "on #{audit.created_at.to_fs(:govuk_date_and_time)}"
    end

  private

    def provider_archived_or_restored?
      audit.auditable_type == "Provider" &&
        audit.action == "update" &&
        audit.audited_changes&.key?("archived_at")
    end

    def archived_or_restored_action
      old_value, _new_value = audit.audited_changes["archived_at"]
      old_value.nil? ? "archived" : "restored"
    end

    def record_discarded_or_restored?
      audit.action == "update" &&
        audit.audited_changes&.key?("discarded_at")
    end

    def discarded_or_restored_action
      old_value, _new_value = audit.audited_changes["discarded_at"]
      old_value.nil? ? "deleted" : "restored"
    end
  end
end
