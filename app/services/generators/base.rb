module Generators
  class Base
    include ServicePattern

    attr_reader :percentage, :processed_count, :total_count

    def initialize(percentage: 0.5)
      @percentage = percentage
      @processed_count = 0
      @total_count = 0
    end

    def call
      raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

      @total_count = target_providers.count

      # Check if target percentage is already achieved
      return self if already_at_target_percentage?

      providers_to_process = target_providers.order("RANDOM()").limit((@total_count * @percentage).round)

      # Allow subclasses to clear existing data for providers being processed
      clear_existing_data_for_providers(providers_to_process) if respond_to?(:clear_existing_data_for_providers)

      providers_to_process.each do |provider|
        process_provider(provider)
        @processed_count += 1
      end

      self
    end

  private

    def target_providers
      raise NotImplementedError, "Subclasses must implement target_providers"
    end

    def already_at_target_percentage?
      return false if @total_count.zero?

      providers_with_target_data_count = target_providers.joins(existing_target_data_joins).count
      current_percentage = providers_with_target_data_count.to_f / @total_count
      current_percentage >= @percentage
    end

    def existing_target_data_joins
      raise NotImplementedError, "Subclasses must implement existing_target_data_joins"
    end

    def process_provider(provider)
      raise NotImplementedError, "Subclasses must implement process_provider"
    end

    def clear_existing_data_for_providers(providers)
      # Optional method for subclasses to override
    end
  end
end
