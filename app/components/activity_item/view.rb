module ActivityItem
  class View < ApplicationComponent
    ACTIVITY_LABELS = {
      "Provider" => "Provider details",
      "Address" => "Provider address",
      "Accreditation" => "Provider accreditation",
      "Contact" => "Provider contact",
      "User" => "User details"
    }.freeze

    attr_reader :audit

    def initialize(audit:)
      @audit = audit
      super()
    end

    def activity_label
      ACTIVITY_LABELS[audit.auditable_type] || audit.auditable_type
    end

    ACTION_LABELS = {
      "create" => "created",
      "update" => "updated",
      "destroy" => "deleted"
    }.freeze

    def action_text
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
  end
end
