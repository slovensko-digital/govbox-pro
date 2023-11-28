class HealthCheckController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  skip_before_action :set_menu_context

  FETCH_LIMIT = 10
  JOB_STUCK_MINUTES = 30

  def show
    if ActiveRecord::Base.connection.active?
      render status: :ok, json: { ok: true }
    else
      render status: :service_unavailable, json: { ok: false }
    end
  rescue Exception
    render status: :service_unavailable, json: { ok: false }
  end

  def failing_jobs
    failed_jobs = GoodJob::Job.where.not(error: nil).limit(FETCH_LIMIT)
    if failed_jobs.any?
      render status: :service_unavailable,
             json: { failed_jobs: failed_jobs.count == FETCH_LIMIT ? ">#{FETCH_LIMIT}" : failed_jobs.count.to_s }
    else
      render status: :ok, json: { ok: true }
    end
  end

  def stuck_jobs
    stuck_jobs = GoodJob::Job.where(finished_at: nil).where("COALESCE(scheduled_at, created_at) < ?", JOB_STUCK_MINUTES.minutes.ago).limit(11)
    if stuck_jobs.any?
      render status: :service_unavailable,
             json: { stuck_jobs: stuck_jobs.count == FETCH_LIMIT ? ">#{FETCH_LIMIT}" : stuck_jobs.count.to_s }
    else
      render status: :ok, json: { ok: true }
    end
  end
end
