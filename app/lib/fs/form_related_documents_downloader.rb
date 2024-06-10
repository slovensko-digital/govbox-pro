class Fs::FormRelatedDocumentsDownloader < ::Utils::Downloader
  SOURCE_URL = ENV['FS_FORMS_STORAGE_API_URL']
  XSD_PATH = 'schema.xsd'

  attr_reader :fs_form

  def initialize(fs_form)
    @fs_form = fs_form
  end

  def download_related_document_by_type(type)
    return unless @fs_form

    xml_manifest = download_xml_manifest

    case type
    when :xsd
      related_document_path = XSD_PATH
      related_document_type = 'CLS_F_XSD_EDOC'
    when :xslt_html
      related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="screen" or @media-destination="view"]')&.first['full-path']
      related_document_path&.gsub!(/\\/, '/')
      related_document_type = 'CLS_F_XSLT_HTML'
    when :xslt_txt
      related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="sign"]')&.first['full-path']
      related_document_path&.gsub!(/\\/, '/')
      related_document_type = 'CLS_F_XSLT_TXT_SGN'
    when :xsl_fo
      related_document_path = xml_manifest.xpath('//manifest:file-entry[@media-destination="print"]')&.first['full-path']
      related_document_path&.gsub!(/\\/, '/')
      related_document_type = 'CLS_F_XSL_FO'
    end

    download_related_document(path: related_document_path, type: related_document_type)
  end

  def download_related_document(path:, type:)
    @fs_form.related_documents.find_or_initialize_by(
      document_type: type,
      language: 'sk'
    ).tap do |form_related_document|
      form_related_document.data = download(SOURCE_URL + "#{@fs_form.slug}/1.0/#{path}")
      form_related_document.touch if form_related_document.persisted?
      form_related_document.save!
    end
  end

  private

  def download_xml_manifest
    manifest_content = download(SOURCE_URL + "/#{@fs_form.slug}/1.0/META-INF/manifest.xml")
    Nokogiri::XML(manifest_content)
  end
end
