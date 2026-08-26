class ProviderCodeTakenService
  include ServicePattern

  def initialize(code:, effective_on:)
    @code = code
    @effective_on = effective_on
  end

  def call
    Provider.kept.exists?(code:) || ProviderChange.exists?(attribute_name: "code", value: code,
                                                           effective_on: effective_on)
  end

private

  attr_reader :code, :effective_on
end
