class SaveProviderWithRotpIdService
  include ServicePattern

  MAX_RETRIES = 10

  def initialize(provider, validate: true)
    @provider = provider
    @validate = validate
  end

  def call
    if provider.rotp_id.blank?
      save_with_rotp_id
    else
      provider.save!(validate:)
    end
  end

private

  attr_reader :provider, :validate

  def save_with_rotp_id
    attempt = 0

    begin
      provider.rotp_id = RotpIdGeneratorService.call(
        provider.operating_name,
        provider.onboarded_at,
        attempt
      )
      provider.save!(validate:)
    rescue expected_exception_class => e
      raise unless rotp_id_collision?(e)

      attempt += 1
      retry if attempt < MAX_RETRIES

      raise
    end
  end

  def expected_exception_class
    if validate
      ActiveRecord::RecordInvalid
    else
      ActiveRecord::RecordNotUnique
    end
  end

  def rotp_id_collision?(error)
    case error
    when ActiveRecord::RecordInvalid
      error.record.errors.of_kind?(:rotp_id, :taken)
    when ActiveRecord::RecordNotUnique
      error.cause.is_a?(PG::UniqueViolation) &&
        error.cause.message.include?("(rotp_id)")
    else
      false
    end
  end
end
