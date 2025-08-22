module GovukDateValidation
  extend ActiveSupport::Concern

  class_methods do
    def validates_govuk_date(field_name, **options)
      options = { required: true }.merge(options)

      validate do
        GovukDateValidation::Validator.new(self, field_name, **options).validate
      end
    end
  end

  class Validator
    def initialize(record, field_name, **options)
      @record = record
      @field_name = field_name
      @options = options
      @human_name = options[:human_name] || field_name.to_s.humanize.downcase
    end

    def validate
      @date_value = @record.public_send(@field_name)

      check_date_components

      if @date_value.is_a?(Date)
        validate_temporal_constraints
        validate_relative_constraints
      end
    end

  private

    attr_reader :record, :field_name, :options, :human_name, :date_value

    def check_date_components
      day_field = :"#{field_name}_day"
      month_field = :"#{field_name}_month"
      year_field = :"#{field_name}_year"

      return unless record.respond_to?(day_field)

      day = record.public_send(day_field)
      month = record.public_send(month_field)
      year = record.public_send(year_field)

      if day.blank? && month.blank? && year.blank?
        if options[:required]
          add_date_error(:blank, "Enter #{human_name}")
        end
        return
      end

      missing_parts = []
      missing_parts << "day" if day.blank?
      missing_parts << "month" if month.blank?
      missing_parts << "year" if year.blank?

      if missing_parts.any?
        error_message = build_incomplete_error_message(missing_parts)
        add_date_error(:incomplete, error_message)
        return
      end

      if year.present? && year.to_s.length != 4
        add_date_error(:invalid_year, "Year must include 4 numbers")
        return
      end

      if date_value.nil?
        add_date_error(:real_date, "#{human_name.capitalize} must be a real date")
      end
    end

    def validate_temporal_constraints
      today = Date.current

      if options[:past] && date_value >= today
        add_date_error(:must_be_past, "#{human_name.capitalize} must be in the past")
      elsif options[:future] && date_value <= today
        add_date_error(:must_be_future, "#{human_name.capitalize} must be in the future")
      elsif options[:today_or_past] && date_value > today
        add_date_error(:must_be_today_or_past, "#{human_name.capitalize} must be today or in the past")
      elsif options[:today_or_future] && date_value < today
        add_date_error(:must_be_today_or_future, "#{human_name.capitalize} must be today or in the future")
      end
    end

    def validate_relative_constraints
      if options[:after]
        other_date = record.public_send(options[:after])
        if other_date.is_a?(Date) && date_value <= other_date
          other_name = options[:after].to_s.humanize.downcase
          add_date_error(:must_be_after,
                         "#{human_name.capitalize} must be after #{other_date.strftime('%-d %B %Y')} (#{other_name})")
        end
      end

      if options[:same_or_after]
        other_date = record.public_send(options[:same_or_after])
        if other_date.is_a?(Date) && date_value < other_date
          other_name = options[:same_or_after].to_s.humanize.downcase
          add_date_error(
            :must_be_same_or_after,
            "#{human_name.capitalize} must be the same as or after " \
            "#{other_date.strftime('%-d %B %Y')} (#{other_name})"
          )
        end
      end

      if options[:before]
        other_date = record.public_send(options[:before])
        if other_date.is_a?(Date) && date_value >= other_date
          other_name = options[:before].to_s.humanize.downcase
          add_date_error(
            :must_be_before,
            "#{human_name.capitalize} must be before " \
            "#{other_date.strftime('%-d %B %Y')} (#{other_name})"
          )
        end
      end

      if options[:same_or_before]
        other_date = record.public_send(options[:same_or_before])
        if other_date.is_a?(Date) && date_value > other_date
          other_name = options[:same_or_before].to_s.humanize.downcase
          add_date_error(
            :must_be_same_or_before,
            "#{human_name.capitalize} must be the same as or before " \
            "#{other_date.strftime('%-d %B %Y')} (#{other_name})"
          )
        end
      end

      if options[:between]
        start_date, end_date = options[:between]
        if start_date.is_a?(Date) && end_date.is_a?(Date) && !date_value.between?(start_date, end_date)
          add_date_error(
            :must_be_between,
            "#{human_name.capitalize} must be between " \
            "#{start_date.strftime('%-d %B %Y')} and #{end_date.strftime('%-d %B %Y')}"
          )
        end
      end
    end

    def build_incomplete_error_message(missing_parts)
      case missing_parts.length
      when 1
        part = missing_parts.first
        if part == "year"
          "Year must include 4 numbers"
        else
          "#{human_name.capitalize} must include a #{part}"
        end
      when 2
        if missing_parts.include?("year")
          "#{human_name.capitalize} must include a #{missing_parts.reject { |p|
            p == "year"
          }.join(" and ")} and year must include 4 numbers"
        else
          "#{human_name.capitalize} must include a #{missing_parts.join(" and ")}"
        end
      else
        "Enter #{human_name}"
      end
    end

    def add_date_error(key, message = nil)
      if message
        record.errors.add(field_name, message)
      else
        record.errors.add(field_name, key)
      end
    end
  end
end
