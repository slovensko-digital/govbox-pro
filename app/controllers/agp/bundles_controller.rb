module Agp
  class BundlesController < ApplicationController
    before_action :ensure_tenant_agp_feature
    before_action :set_bundle, except: %i[new create]
    before_action :set_agp_sdk_file, except: %i[new create], unless: -> { @bundle.init? || @bundle.init_failed? }
    before_action :set_message_objects, only: %i[new create]

    def show
      authorize @bundle

      respond_to do |format|
        format.html
        format.json { render json: bundle_sync_status }
      end
    end

    def new
      authorize(Agp::Bundle)
      @bundle = Agp::Bundle.find_or_initialize_from_message_objects(Current.tenant, @message_objects, signer_user: Current.user)
    end

    def create
      authorize(Agp::Bundle)
      @bundle = find_or_build_bundle
      @bundle.contracts.each { |contract| contract.signer_user ||= Current.user }

      if @bundle.save
        begin
          Agp::UploadBundleJob.new.perform(@bundle)
          redirect_to @bundle
        rescue => e
          Rails.logger.warn("AGP bundle #{@bundle.bundle_identifier} initialization failed, falling back to direct Autogram signing: #{e.message}")
          render_direct_signing_fallback || raise
        end
      else
        render_direct_signing_fallback || render(:new, status: :unprocessable_entity)
      end
    end

    private

    def bundle_params
      params.require(:agp_bundle).permit(:bundle_identifier, contracts_attributes: %i[contract_identifier message_object_id message_object_updated_at])
    end

    def ensure_tenant_agp_feature
      head :not_found and return unless Current.tenant.agp_signing_enabled?
    end

    def find_or_build_bundle
      bundle = Agp::Bundle.find_by(bundle_identifier: bundle_params[:bundle_identifier])
      return Agp::Bundle.new(**bundle_params, tenant: Current.tenant) unless bundle

      bundle.status = :init if bundle.init_failed? || bundle.failed?
      bundle
    end

    def set_bundle
      @bundle = Agp::Bundle.where(tenant: Current.tenant).find(params[:id])
    end

    def set_agp_sdk_file
      @agp_sdk_file = File.join(Current.tenant.agp_api_url, "sdk.js")
    end

    def set_message_objects
      message_thread_ids = policy_scope(MessageThread).where(id: params[:message_thread_ids] || []).pluck(:id)
      message_thread_ids = policy_scope(MessageObject)
                         .joins(:tags, message: :thread)
                         .where(message_threads: { id: message_thread_ids })
                         .where(tags: { id: [Current.user.signature_requested_from_tag, Current.tenant.signer_group.signature_requested_from_tag] })

      message_ids = params[:object_ids]

      ids = []
      ids += message_thread_ids if message_thread_ids.present?
      ids += message_ids if message_ids.present?

      @message_objects = policy_scope(MessageObject).where(id: ids.compact).distinct
    end

    def render_direct_signing_fallback
      if params[:message_draft_id].present?
        @message_draft = policy_scope(MessageDraft).find(params[:message_draft_id])
        render template: "message_drafts/signings/new", status: :ok
      elsif params[:message_thread_ids].present?
        @message_thread_ids = policy_scope(MessageThread).where(id: params[:message_thread_ids] || []).pluck(:id)
        render template: "message_threads/bulk/signings/start", status: :ok
      end
    end

    def bundle_sync_status
      total_contracts_count = @bundle.contracts.count
      signed_contracts_count = @bundle.contracts.joins(:message_object).where(message_objects: { is_signed: true }).count

      {
        total_contracts_count: total_contracts_count,
        signed_contracts_count: signed_contracts_count,
        fully_synced: total_contracts_count.positive? && signed_contracts_count == total_contracts_count
      }
    end
  end
end
