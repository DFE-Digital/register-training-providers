class DemoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "[#{Time.current}] Running scheduled DemoJob with #{args.inspect}"
  end
end
