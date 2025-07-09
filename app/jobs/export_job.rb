class ExportJob < ApplicationJob
  queue_as :default

  def perform(export)
    export.message_threads.each do |message_thread|
      message_thread.messages.each do |message|
        message.objects.each do |object|
          filepath = export.export_object_filepath(object)
          # TODO

        end
      end
    end

    export.user.notifications.create!(
      type: Notifications::ExportFinished,
      export: export
    )
  end
end
