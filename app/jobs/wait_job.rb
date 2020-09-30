# frozen_string_literal: true

class WaitJob
  include SuckerPunch::Job
  workers 1
  max_jobs 1

  def perform
    SyncJob.perform_async
  end
end
