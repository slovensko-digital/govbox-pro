# frozen_string_literal: true

module Admin
  class AutomationWebhooksController < ApplicationController
    before_action :set_webhook, except: [:index, :new, :create]
    before_action :set_list_values, only: [:new, :edit]

    def index
      authorize [:admin, ::Automation::Webhook]
      @webhooks = Current.tenant.automation_webhooks
    end

    def new
      @webhook = Current.tenant.automation_webhooks.new
      authorize([:admin, @webhook])
    end

    def edit
      authorize([:admin, @webhook])
    end

    def create
      @webhook = Current.tenant.automation_webhooks.new(webhook_params)
      authorize([:admin, @webhook])
      if @webhook.save!
        redirect_to admin_tenant_automation_webhooks_url(Current.tenant), notice: "Webhook was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize([:admin, @webhook])
      if @webhook.update(webhook_params)
        redirect_to admin_tenant_automation_webhooks_url(Current.tenant), notice: "Webhook was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [:admin, @webhook]
      if @webhook.destroy
        redirect_to admin_tenant_automation_webhooks_path(Current.tenant), notice: "Webhook was successfully destroyed"
      else
        redirect_to admin_tenant_automation_webhooks_path(Current.tenant), alert: @webhook.errors.full_messages[0]
      end

    end

    private

    def set_webhook
      @webhook = Current.tenant.automation_webhooks.find(params[:id])
    end

    def webhook_params
      params.require(:automation_webhook).permit(:secret, :auth, :name, :url, :request_type)
    end

    def set_list_values
      @request_types = [
        [t('webhooks.request_types.plain'), 'plain'],
        [t('webhooks.request_types.standard'), 'standard']
      ]
      @auth_types = [[t('webhooks.auth_types.none'), 'none']]
    end
  end
end
