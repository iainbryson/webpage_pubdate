# frozen_string_literal: true

require 'test_helper'
require 'pry'
require 'yaml'
require 'csv'

class WebpagePubdateTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert ::WebpagePubdate::VERSION
  end

  def test_it_parses_pages
    YAML.load_file('./test/data/test_urls.yaml').each do |url, expected_pubdate|
      pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate
      assert pubdate, "#{url} unable to find pubdate"
      assert_equal(pubdate, expected_pubdate) if expected_pubdate
    end
  end
end
