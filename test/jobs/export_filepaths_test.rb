require "test_helper"

class ExportFilepathsTest < ActiveJob::TestCase
  setup do
    @job = ExportJob.new
    @object = message_objects(:fs_accountants_outbox_form)
    @thread = @object.message.thread
    @export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [@thread.id],
      settings: { "messages" => true, "default" => true, "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )
  end

  test "PDF only preview lists nested PDF paths with unique names" do
    2.times do |index|
      @object.nested_message_objects.create!(name: "form#{index}.pdf", mimetype: Utils::PDF_MIMETYPE, content: "%PDF-form")
    end
    @export.update_settings("originals" => false, "pdf" => true, "templates" => { "default" => "{{ subor.nazov }}" })

    assert_equal ["SVDPHv20.pdf", "SVDPHv20 (1).pdf"], @job.export_object_filepaths(@object, export: @export)
    assert_equal ["SVDPHv20 (1).pdf", "SVDPHv20 (2).pdf"], @job.export_object_filepaths(@object, export: @export, other_file_names: ["SVDPHv20.pdf"])
  end

  test "filepath substitutes thread title" do
    assert_equal "#{@thread.title}/SVDPHv20.asice", @job.export_object_filepath(@object, export: @export)
  end

  test "filepath handles nil thread title" do
    @object.message.thread.stub(:title, nil) do
      assert_equal "SVDPHv20.asice", @job.export_object_filepath(@object, export: @export)
    end
  end

  test "filepath sanitizes slashes in thread title" do
    { "DPH/2025/Q1" => "DPH-2025-Q1", "a/b/c" => "a-b-c" }.each do |title, sanitized_title|
      @object.message.thread.stub(:title, title) do
        assert_equal "#{sanitized_title}/SVDPHv20.asice", @job.export_object_filepath(@object, export: @export)
      end
    end
  end

  test "filepath sanitizes slashes in file name" do
    @export.update_settings("templates" => { "default" => "vlakno/{{ subor.nazov }}" })
    @object.stub(:name, "report/2025/file.pdf") do
      assert_equal "vlakno/report-2025-file.pdf", @job.export_object_filepath(@object, export: @export)
    end
  end

  test "filepath strips path traversal" do
    @export.update_settings("templates" => { "default" => "../{{ vlakno.id }}/{{ subor.nazov }}" })
    assert_equal "#{@thread.id}/SVDPHv20.asice", @job.export_object_filepath(@object, export: @export)
  end

  test "filepath uses a fallback name when the object has no name" do
    @export.update_settings("templates" => { "default" => "{{ subor.nazov }}" })
    @object.stub(:name, nil) do
      assert_equal "#{I18n.t('no_message_object_name')}.asice", @job.export_object_filepath(@object, export: @export)
    end
  end

  test "form template and variables use the box export form" do
    form = fs_forms(:SVDPHv20)
    form.update!(subtype_name: "Dodatočný")
    @thread.update!(metadata: @thread.metadata.merge("fs_form_id" => form.id))
    @export.update_settings("default" => false, "by_form" => { form.slug => true }, "templates" => { form.slug => "{{ vlakno.formular }}/{{ vlakno.formular_bez_verzie }}/{{ subor.nazov }}" })

    assert_equal "DOD_SVDPHv20/DOD_SVDPH/SVDPHv20.asice", @job.export_object_filepath(@object, export: @export)
  end

  test "non FS export uses the generic box contract without an FS lookup" do
    object = message_objects(:ssd_main_general_one_attachment)
    object.thread.update!(metadata: { "fs_form_id" => fs_forms(:SVDPHv20).id })
    @export.update_settings("templates" => { "default" => "{{ vlakno.formular }}{{ subor.nazov }}" })

    Fs::Form.stub(:find_by, ->(**) { flunk "Non-FS boxes must not look up FS forms" }) do
      assert_equal object.name, @job.export_object_filepath(object, export: @export)
    end
  end
end
