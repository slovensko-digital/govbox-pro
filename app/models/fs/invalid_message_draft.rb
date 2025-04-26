class Fs::InvalidMessageDraft < Fs::MessageDraft
  after_create do
    add_cascading_tag(thread.box.tenant.submission_error_tag!)
  end
end
