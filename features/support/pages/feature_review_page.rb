module Pages
  class FeatureReviewPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def app_info
      page.all('.app_info').map { |app_info_element|
        Sections::AppInfoSection.from_element(app_info_element)
      }
    end

    def builds(for_app: nil)
      verify!
      app_container(for_app).all('.build').map { |build_line|
        Sections::BuildSection.from_element(build_line)
      }
    end

    def uat_url
      page.find('.uat_url').text
    end

    private

    attr_reader :page, :url_helpers

    def verify!
      fail "Expected to be on a Feature Review page, but was on #{page.current_url}" unless on_page?
    end

    def on_page?
      page.current_url =~ Regexp.new(Regexp.escape(url_helpers.feature_reviews_path))
    end

    def app_container(app_name)
      return page unless app_name
      page.find(".#{app_name}")
    end
  end
end
