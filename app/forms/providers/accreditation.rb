module Providers
  class Accreditation
    include ActiveModel::Model
    include ActiveModel::Attributes
    include SaveAsTemporary
    include GovukDateValidation

    PARAM_CONVERSION = {
      "start_date(3i)" => "start_date_day",
      "start_date(2i)" => "start_date_month",
      "start_date(1i)" => "start_date_year",
      "end_date(3i)" => "end_date_day",
      "end_date(2i)" => "end_date_month",
      "end_date(1i)" => "end_date_year",
    }.freeze

    attribute :number, :string
    attribute :provider_id, :integer
    attribute :start_date_day, :integer
    attribute :start_date_month, :integer
    attribute :start_date_year, :integer
    attribute :end_date_day, :integer
    attribute :end_date_month, :integer
    attribute :end_date_year, :integer
    attribute :start_date, :date
    attribute :end_date, :date

    def self.model_name
      ActiveModel::Name.new(self, nil, "Accreditation")
    end

    def self.i18n_scope
      :activerecord
    end

    def self.from_accreditation(accreditation)
      form = new(
        number: accreditation.number,
        start_date: accreditation.start_date,
        end_date: accreditation.end_date,
        provider_id: accreditation.provider_id
      )

      if accreditation.start_date.present?
        form.start_date_day = accreditation.start_date.day
        form.start_date_month = accreditation.start_date.month
        form.start_date_year = accreditation.start_date.year
      end

      if accreditation.end_date.present?
        form.end_date_day = accreditation.end_date.day
        form.end_date_month = accreditation.end_date.month
        form.end_date_year = accreditation.end_date.year
      end

      form
    end

    validates :number, presence: true, accreditation_number: true
    validates :provider_id, presence: true
    validates_govuk_date :start_date, required: true, human_name: "date accreditation starts"
    validates_govuk_date :end_date, required: false, same_or_after: :start_date, human_name: "date accreditation ends"

    def initialize(attributes = {})
      super
      convert_date_components unless start_date.present? || end_date.present?
    end

    def to_accreditation_attributes
      convert_date_components
      {
        number:,
        start_date:,
        end_date:,
        provider_id:
      }.compact
    end

    def serializable_hash(_options = nil)
      {
        "number" => number,
        "start_date" => start_date,
        "end_date" => end_date,
        "provider_id" => provider_id,
        "start_date_day" => start_date_day,
        "start_date_month" => start_date_month,
        "start_date_year" => start_date_year,
        "end_date_day" => end_date_day,
        "end_date_month" => end_date_month,
        "end_date_year" => end_date_year
      }
    end

  private

    def convert_date_components
      self.start_date = build_date_from_components(:start_date)
      self.end_date = build_date_from_components(:end_date)
    end

    def build_date_from_components(date_field)
      year = send("#{date_field}_year")
      month = send("#{date_field}_month")
      day = send("#{date_field}_day")

      return nil unless year.present? && month.present? && day.present?

      begin
        Date.new(year, month, day)
      rescue ArgumentError
        nil
      end
    end
  end
end
