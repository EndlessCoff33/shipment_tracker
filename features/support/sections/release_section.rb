module Sections
  class ReleaseSection
    include Virtus.value_object

    values do
      # attribute :id, String
      attribute :date, Time
      attribute :message, String
      attribute :feature_review_status, String
      attribute :feature_review_path, String
    end

    def self.from_element(release_element)
      values = release_element.all('td').to_a
      new(
        # id:      values.fetch(0).text,
        date:    values.fetch(1).text,
        message: values.fetch(2).text,
        feature_review_status: values.fetch(3).text,
        feature_review_path: extract_href_if_exists(values.fetch(3)),
      )
    end

    def self.extract_href_if_exists(element)
      element.find('a')['href'] if element.has_css?('a')
    end
  end
end
