class MessagesController < ApplicationController
  before_action :set_message

  # TODO: Only for rule test
  after_action :run_rules, only: [:show]

  def show
    authorize @message
  end

  private


  # TODO: Only for rule test
  def run_rules
    Automation.run_rules_for(@message, :message_created)
  end

  def set_message
    @message = policy_scope(Message).find(params[:id])
  end
end
