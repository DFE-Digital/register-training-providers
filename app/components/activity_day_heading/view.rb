module ActivityDayHeading
  class View < ApplicationComponent
    attr_reader :date

    def initialize(date:)
      @date = date
      super()
    end

    def day_label
      if date == Time.current.to_date
        "Today"
      elsif date == Time.current.to_date - 1.day
        "Yesterday"
      else
        date.to_fs(:govuk)
      end
    end
  end
end
