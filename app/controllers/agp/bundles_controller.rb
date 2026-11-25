module Agp
  class BundlesController < ApplicationController
    include TurboReload

    before_action :ensure_tenant_agp_feature
    before_action :set_bundle, only: %i[show sync]
    before_action :set_message_objects, only: %i[new create]

    def show
      authorize @bundle

      respond_to do |format|
        format.html
        format.json { render json: @bundle.sync_status }
      end
    end

    def new
      authorize(Agp::Bundle)
    end

    def create
      authorize(Agp::Bundle)

      begin
        @bundle = Agp::Bundle.find_or_create_for!(tenant: Current.tenant, signer_user: Current.user, message_objects: @message_objects)
        @bundle.upload!(webhook_url: agp_webhook_url) unless @bundle.created?
      rescue StandardError => e
        Rails.logger.warn("AGP bundle #{@bundle&.bundle_identifier} initialization failed, falling back to direct Autogram signing: #{e.message}")
        return render_direct_signing_fallback || raise
      end

      redirect_to agp_bundle_path(@bundle)
    end

    # Called by the signing page as soon as AGP reports the documents as signed, so GovBox does not need
    # to wait for the webhook (which may not reach GovBox at all, e.g. in development).
    def sync
      authorize @bundle

      Agp::SyncBundleJob.set(queue: :asap).perform_later(@bundle) if @bundle.created?

      head :accepted
    end

    private

    def ensure_tenant_agp_feature
      head :not_found and return unless Current.tenant.agp_signing_enabled?
    end

    def set_bundle
      @bundle = policy_scope(Agp::Bundle).find(params[:id])
    end

    def set_message_objects
      message_objects = if params[:message_thread_ids].present?
        message_thread_ids = policy_scope(MessageThread).where(id: params[:message_thread_ids]).pluck(:id)

        policy_scope(MessageObject)
          .joins(:tags, message: :thread)
          .where(message_threads: { id: message_thread_ids })
          .where(tags: { id: [Current.user.signature_requested_from_tag, Current.tenant.signer_group.signature_requested_from_tag] })
      else
        policy_scope(MessageObject).where(id: params[:object_ids] || [])
      end

      # the same check as when a signed document is uploaded directly from Autogram (MessageObjectsController#update)
      @message_objects = message_objects.distinct.includes(:message).select { |message_object| policy(message_object).update? }

      return if @message_objects.any?

      request_turbo_reload
      redirect_back fallback_location: message_threads_path, alert: t("bulk.signing.nothing_to_sign"), status: :see_other
    end

    def agp_webhook_url
      ENV["AGP_WEBHOOK_URL"].presence || agp_webhooks_url
    end

    def render_direct_signing_fallback
      if params[:message_draft_id].present?
        @message_draft = policy_scope(MessageDraft).find(params[:message_draft_id])
        render template: "message_drafts/signings/new", status: :ok
      elsif params[:message_thread_ids].present?
        @message_thread_ids = policy_scope(MessageThread).where(id: params[:message_thread_ids]).pluck(:id)
        render template: "message_threads/bulk/signings/start", status: :ok
      end
    end
  end
end
