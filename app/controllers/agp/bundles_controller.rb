module Agp
  class BundlesController < ApplicationController
    before_action :ensure_tenant_agp_feature
    before_action :set_bundle, except: %i[new create]
    before_action :set_agp_sdk_file, except: %i[new create], unless: -> { @bundle.init? || @bundle.init_failed? }
    before_action :set_message_objects, only: %i[new create]

    def show
      authorize @bundle

      # respond_to do |format|
      #   format.turbo_stream
      # end
    end

    def new
      authorize(Agp::Bundle)
      @bundle = Agp::Bundle.find_or_initialize_from_message_objects(Current.tenant, @message_objects)
    end

    def create
      authorize(Agp::Bundle)
      @bundle = Agp::Bundle.find_by(bundle_identifier: bundle_params[:bundle_identifier]) || Agp::Bundle.new(**bundle_params, tenant: Current.tenant)
      if @bundle.save
        Agp::UploadBundleJob.new.perform(@bundle) if @bundle.init?
        redirect_to @bundle
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def bundle_params
      params.require(:agp_bundle).permit(:bundle_identifier, contracts_attributes: %i[contract_identifier message_object_id message_object_updated_at])
    end

    def ensure_tenant_agp_feature
      head :not_found and return unless Current.tenant.feature_enabled?(:autogram_portal)
    end

    def set_bundle
      @bundle = Agp::Bundle.where(tenant: Current.tenant).find(params[:id])
    end

    def set_agp_sdk_file
      @agp_sdk_file = File.join(ENV.fetch("AGP_API_URL", nil), "sdk.js")
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
  end
end
