module Providers
  class Accreditation
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
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
    attribute :start_date, :date
    attribute :end_date, :date
    attribute :provider_id, :integer

    attribute :start_date_day, :integer
    attribute :start_date_month, :integer
    attribute :start_date_year, :integer
    attribute :end_date_day, :integer
    attribute :end_date_month, :integer
    attribute :end_date_year, :integer

    def self.model_name
      ActiveModel::Name.new(self, nil, "Accreditation")
    end

    def self.i18n_scope
      :activerecord
    end

    validates :number, presence: true, accreditation_number: true

    validates_govuk_date :start_date, required: true, human_name: "date accreditation starts"
    validates_govuk_date :end_date, required: false, same_or_after: :start_date, human_name: "date accreditation ends"

    before_validation :convert_date_components

    alias_method :serializable_hash, :attributes

    def initialize(attributes = {})
      super
      convert_date_components
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
