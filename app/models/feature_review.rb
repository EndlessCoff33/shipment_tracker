class FeatureReview
  include Virtus.value_object

  values do
    attribute :url, String
    attribute :versions, Array
  end

  def app_versions
    query_hash.fetch('apps', {}).select { |_name, version| version.present? }
  end

  def path
    URI(url).request_uri
  end

  def uat_url
    uat_uri.try(:to_s)
  end

  def uat_host
    uat_uri.try(:host)
  end

  private

  def query_hash
    Rack::Utils.parse_nested_query(URI(url).query)
  end

  def uat_uri
    uat_url_param = query_hash.fetch('uat_url', nil)
    Addressable::URI.heuristic_parse(uat_url_param, scheme: 'http')
  end
end
