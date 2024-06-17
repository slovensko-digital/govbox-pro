# frozen_string_literal: true

class Fs::FormPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def forms_list?
    true
  end

  def form_selector?
    forms_list?
  end

  def search_forms_list?
    forms_list?
  end

  def form_selected?
    forms_list?
  end
end
