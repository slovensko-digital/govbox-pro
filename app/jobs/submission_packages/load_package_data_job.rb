require 'csv'

class SubmissionPackages::LoadPackageDataJob < ApplicationJob
  queue_as :high_priority

  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(submission, submission_path)
    raise "Submission info missing in CSV" unless submission

    Dir.each_child(submission_path) do |subdirectory_name|
      case subdirectory_name
      when "podpisane"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), true, false)
      when "podpisat"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), false, true)
      when "nepodpisovat"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), false, false)
      else
        raise "Found extra content!"
      end
    end

    submission.update(status: "created")

    unless submission.has_one_form?
      submission.update(status: "corrupt")
    end
  rescue StandardError
    submission.update(status: "invalid") if submission
  end

  private

  def load_submission_objects(submission, objects_path, signed, to_be_signed)
    Dir.foreach(objects_path) do |filename|
      next if filename == '.' or filename == '..'

      raise "Found extra content!" if File.directory?(filename)

      Submissions::Object.create(
        submission_id: submission.id,
        uuid: uuid,
        name: filename,
        content: File.read(File.join(objects_path, filename)),
        form: form?(submission, filename),
        signed: signed,
        to_be_signed: to_be_signed
      )
    end
  end

  def form?(submission, filename)
    file_basename = File.basename(filename, ".*")

    # Form file must have the same name as subfolder
    file_basename == submission.package_subfolder
  end

  delegate :uuid, to: self
end
