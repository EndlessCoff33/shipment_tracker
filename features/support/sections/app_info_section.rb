require_relative 'short_commit_sha'

module Sections
  class AppInfoSection
    include Virtus.value_object

    values do
      attribute :app_name, String
      attribute :version, ShortCommitSha
    end

    def self.from_element(app_info_element)
      new(
        app_name: app_info_element.find('.name').text,
        version: app_info_element.find('.version').text,
      )
    end
  end
end
