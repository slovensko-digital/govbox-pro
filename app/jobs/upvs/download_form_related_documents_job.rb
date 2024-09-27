module Upvs
  class DownloadFormRelatedDocumentsJob < ApplicationJob
    def perform(upvs_form, downloader: ::Upvs::FormRelatedDocumentsDownloader)
      upvs_form_downloader = downloader.new(upvs_form)

      upvs_form_downloader.download_related_document_by_type(:xsd)
      upvs_form_downloader.download_related_document_by_type(:xslt_html)
      upvs_form_downloader.download_related_document_by_type(:xsl_fo)
    end
  end
end
