require "test_helper"

class Notifications::ExportFinishedViewTest < ActionView::TestCase
  test "lists the PDFs the export skipped and offers to try again later" do
    notification = export_finished(skipped_pdf_paths: %w[a.pdf b.pdf])

    render partial: "notifications/export_finisheds/export_finished", locals: { notification: notification }

    assert_includes rendered, "a.pdf"
    assert_includes rendered, "b.pdf"
    assert_includes rendered, edit_message_threads_bulk_export_path(notification.export)
    assert_includes rendered, "príliš veľké", "trying again does not help a form too large for a PDF"
  end

  test "keeps a long list of skipped PDFs short" do
    notification = export_finished(skipped_pdf_paths: (1..7).map { |number| "#{number}.pdf" })

    render partial: "notifications/export_finisheds/export_finished", locals: { notification: notification }

    assert_includes rendered, "5.pdf"
    assert_not_includes rendered, "6.pdf"
    assert_includes rendered, "a ďalšie (2)"
  end

  private

  def export_finished(skipped_pdf_paths:)
    export = Export.create!(user: users(:accountants_basic), skipped_pdf_paths: skipped_pdf_paths)
    Notifications::ExportFinished.new(user: export.user, export: export)
  end
end
