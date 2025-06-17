require "rails_helper"

RSpec.describe DemoJob, type: :job do
  it "enqueues the job" do
    expect {
      DemoJob.perform_later("test")
    }.to have_enqueued_job(DemoJob).with("test")
  end
end
