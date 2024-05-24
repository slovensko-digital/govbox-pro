module Upvs
  class FormRelatedDocumentsDownloader < ::Utils::Downloader
    SOURCE_URL = ENV['FORMS_STORAGE_API_URL']
    XSD_PATH = 'schema.xsd'

    attr_reader :upvs_form

    def initialize(upvs_form)
      @upvs_form = upvs_form
    end

    def download_related_document_by_type(type)
      return unless @upvs_form

      xml_manifest = download_xml_manifest

      case type
      when :xsd
        related_document_path = XSD_PATH
        related_document_type = 'CLS_F_XSD_EDOC'
      when :xslt_html
        related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="screen"]')&.first
        related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="view"]')&.first unless related_document_path.present?
        related_document_path = related_document_path['full-path']
        related_document_path&.gsub!(/\\/, '/')
        related_document_type = 'CLS_F_XSLT_HTML'
      when :xsl_fo
        related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="print"]')&.first['full-path']
        related_document_path&.gsub!(/\\/, '/')
        related_document_type = 'CLS_F_XSL_FO'
      end

      download_related_document(path: related_document_path, type: related_document_type)
    end

    def download_related_document(path:, type:)
      @upvs_form.related_documents.find_or_initialize_by(
        document_type: type,
        language: 'sk'
      ).tap do |form_related_document|
        form_related_document.data = download(SOURCE_URL + "/#{upvs_form.identifier}/#{upvs_form.version}/#{path}")
        form_related_document.touch if form_related_document.persisted?
        form_related_document.save!
      end
    end

    private

    def download_xml_manifest
      manifest_content = download(SOURCE_URL + "/#{@upvs_form.identifier}/#{@upvs_form.version}/META-INF/manifest.xml")
      Nokogiri::XML(manifest_content)
    end
  end
end
