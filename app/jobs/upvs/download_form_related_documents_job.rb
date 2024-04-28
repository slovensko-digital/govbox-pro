module Upvs
  class DownloadFormRelatedDocumentsJob < ApplicationJob
    queue_as :default

    def perform(upvs_form)
      downloader = ::Upvs::FormRelatedDocumentsDownloader.new(upvs_form)

      downloader.download_related_document_by_type(:xsd)
      downloader.download_related_document_by_type(:xslt_html)
      downloader.download_related_document_by_type(:xsl_fo)
    end
  end
end
