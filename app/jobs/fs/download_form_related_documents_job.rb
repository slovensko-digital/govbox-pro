class Fs::DownloadFormRelatedDocumentsJob < ApplicationJob
  def perform(fs_form, downloader: ::Fs::FormRelatedDocumentsDownloader)
    fs_form_downloader = downloader.new(fs_form)

    fs_form_downloader.download_related_document_by_type(:xsd)
    fs_form_downloader.download_related_document_by_type(:xslt_txt)
    fs_form_downloader.download_related_document_by_type(:xslt_html)
  end
end
