class Fs::FormsController < ApplicationController
  before_action :authorize_forms
  before_action :load_forms_list, only: [:form_selector, :forms_list]

  def form_selector
  end

  def forms_list
  end

  def search_forms_list
    @forms_list = Fs::Form.where('unaccent(name) ILIKE unaccent(?) OR unaccent(identifier) ILIKE unaccent(?) OR unaccent(group_slug) ILIKE unaccent(?)', "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
                          .first(10)
                          .pluck(:name, :id)
                          .map { |name, id| { id: id, name: name }}
  end

  def form_selected
    @form_name = params[:form_name]
    @form_id = params[:form_id]
  end

  private

  def authorize_forms
    authorize Fs::Form
  end

  def load_forms_list
    @forms_list = Fs::Form.first(10)
                          .pluck(:name, :id)
                          .map { |name, id| { id: id, name: name }}
  end
end
