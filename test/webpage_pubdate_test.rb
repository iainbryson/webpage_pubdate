# frozen_string_literal: true

require 'test_helper'
require 'pry'
require 'yaml'
require 'csv'

# https://coderwall.com/p/ztig5g/validate-urls-in-rails
def url_valid?(url)
  url = begin
          URI.parse(url)
        rescue StandardError
          false
        end
  url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS)
end

class WebpagePubdateTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert_not_nil ::WebpagePubdate::VERSION
  end

  def test_it_parses_pages
    YAML.load_file('./test/data/test_urls.yaml').each do |url, expected_pubdate|
      pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate
      assert pubdate, "#{url} unable to find pubdate"
      assert_equal(pubdate, expected_pubdate) if expected_pubdate
    end
  end

  def test_it_compares_to_existing
    CSV.open('./test/data/factsmachine.csv', 'r', headers: true, col_sep: "\t").each do |row|
      url = row['link'].strip
      year = row['year']
      unless url_valid?(url)
        puts 'invalid url'
        next
      end
      pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate
      puts ">> new [#{pubdate&.year}] exp #{year} -- #{pubdate}  -- #{url}"
      # assert pubdate, "#{url} unable to find pubdate"
      # assert_equal(pubdate.year, row['year']) if expected_pubdate
    end
  end
end
