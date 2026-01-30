# frozen_string_literal: true

module Admin
  class AutomationWebhooksController < ApplicationController
    before_action :set_webhook, except: [:index, :new, :create]

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
        redirect_to admin_tenant_automation_webhooks_url(Current.tenant), notice: "Webhook bol úspešne vytvorený"
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize([:admin, @webhook])
      if @webhook.update(webhook_params)
        redirect_to admin_tenant_automation_webhooks_url(Current.tenant), notice: "Webhook bol úspešne upravený"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize [:admin, @webhook]
      if @webhook.destroy
        redirect_to admin_tenant_automation_webhooks_path(Current.tenant), notice: "Webhook bol úspešne odstránený"
      else
        redirect_to admin_tenant_automation_webhooks_path(Current.tenant), alert: @webhook.errors.full_messages[0]
      end
    end

    private

    def set_webhook
      @webhook = Current.tenant.automation_webhooks.find(params[:id])
    end

    def webhook_params
      params.require(:automation_webhook).permit(:name, :url)
    end
  end
end
