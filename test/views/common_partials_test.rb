require "test_helper"

class CommonPartialsTest < ActionView::TestCase
  include SigningHelper
  test "modal layout keeps its header, content, and dismissal actions" do
    render layout: "common/modal", locals: { header: "Názov <script>" } do
      content_tag(:p, "Obsah modalu")
    end

    assert_select "h3", text: "Názov <script>"
    assert_select "h3 script", count: 0
    assert_select "p", text: "Obsah modalu"
    assert_select '[data-action="keydown.esc@window->turbo-content#remove"]'
    assert_select '[data-action="click->turbo-content#remove"]'
  end

  test "non-closable modal does not expose dismissal actions" do
    render layout: "common/modal", locals: { closable: false } do
      "Obsah"
    end

    assert_select '[data-action*="turbo-content#remove"]', count: 0
  end

  test "modal actions work without a submit block" do
    render partial: "common/modal_actions"

    assert_select "button", text: "Zavrieť", count: 1
    assert_select '[data-action="click->turbo-content#remove"]'
  end

  test "toggleable modal actions use the local modal controller" do
    render layout: "common/modal_actions", locals: { toggleable: true } do
      button_tag("Uložiť", type: :submit)
    end

    assert_select '[data-action="click->modal#close"]'
    assert_select 'button[type="submit"]', text: "Uložiť", count: 1
  end

  test "dropdown layout retains its body and window dismissal action" do
    render layout: "common/options", locals: { id: "test-options" } do
      link_to("Otvoriť", "/example")
    end

    assert_select '[data-action*="click@window->dropdown#hide"]'
    assert_select '[role="menu"][aria-labelledby="test-options"] a[href="/example"]', text: "Otvoriť"
  end

  test "signer names escape markup" do
    user = Struct.new(:name).new('<img src=x onerror="alert(1)">')

    assert_equal '<strong>&quot;&lt;img src=x onerror=&quot;alert(1)&quot;&gt;&quot;</strong>', signer_names([user])
  end
end
