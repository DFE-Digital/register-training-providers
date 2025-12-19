module ActivityDayHeading
  class View < ApplicationComponent
    attr_reader :date

    def initialize(date:)
      @date = date
      super()
    end

    def day_label
      if date == Date.current
        "Today"
      elsif date == Date.current - 1.day
        "Yesterday"
      else
        date.to_fs(:govuk)
      end
    end
  end
end
