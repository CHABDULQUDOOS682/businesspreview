# frozen_string_literal: true

module SolidQueueTestHelper
  def self.ensure_schema!
    SolidQueue::Record.connection_pool.with_connection do |connection|
      next if connection.table_exists?(:solid_queue_jobs)

      load Rails.root.join("db/queue_schema.rb")
    end
  end

  def self.enqueue_job(job_class)
    ensure_schema!
    active_job = job_class.new
    SolidQueue::Job.enqueue(active_job)
  end

  def self.clear_jobs!
    return unless SolidQueue::Record.connection.table_exists?(:solid_queue_jobs)

    SolidQueue::Job.delete_all
  end
end

RSpec.configure do |config|
  config.before(:each, :solid_queue) do
    SolidQueueTestHelper.ensure_schema!
  end

  config.after(:each, :solid_queue) do
    SolidQueueTestHelper.clear_jobs!
  end
end
