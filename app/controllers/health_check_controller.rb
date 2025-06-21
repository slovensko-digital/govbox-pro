class HealthCheckController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_before_action :set_menu_context

  def show
    ActiveRecord::Base.connection.verify! # connect if not connected

    if ActiveRecord::Base.connection.active?
      render status: :ok, json: { ok: true }
    else
      render status: :service_unavailable, json: { ok: false }
    end
  end

  def failing_jobs
    failed_jobs = GoodJob::Job.discarded.count
    if failed_jobs.any?
      render status: :service_unavailable,
             json: { ok: false }
    else
      render status: :ok, json: { ok: true }
    end
  end

  def stuck_jobs
    stuck_jobs = GoodJob::Job.where(finished_at: nil).where("COALESCE(scheduled_at, created_at) < ?", 30.minutes.ago)
    if stuck_jobs.any?
      render status: :service_unavailable, json: { ok: false }
    else
      render status: :ok, json: { ok: true }
    end
  end
end
