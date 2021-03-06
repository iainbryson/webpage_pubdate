# frozen_string_literal: true

require 'test_helper'
require 'pry'
require 'yaml'
require 'csv'

#
#  bundle exec rake test TEST=test/debug_test.rb TESTOPTS="--name=test_it_debug_test -v"
# Easy test single url
#
class WebpagePubdateDebugTest < Minitest::Test
  def test_it_debug_test
    tz = ActiveSupport::TimeZone.new('UTC')

    # url = 'https://www.bloomberg.com/news/articles/2018-07-06/vegans-are-rising-in-france'
    # url = 'https://www.axios.com/walmart-ammo-sales-open-carry-shopper-poll-6b21d0d2-a55c-45b1-9348-aaa794406bab.html'
    # url = 'https://www.statista.com/chartoftheday/'
    # url = 'https://www.bloomberg.com/authors/AR3OYuAmvcU/noah-smith' <- not an article
    # url = 'https://www.bloomberg.com/news/articles/2018-06-19/coal-is-being-squeezed-out-of-power-industry-by-cheap-renewables'
    # url = 'https://www.bls.gov/bdm/entrepreneurship/entrepreneurship.htm'
    url = 'https://ftalphaville.ft.com/2018/01/17/2197783/that-time-when-american-banks-basically-existed-to-fund-the-government/'
    expected_pubdate = tz.parse("2018-01-17")

    pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate({ debug: true })
    assert pubdate, "#{url} unable to find pubdate"
    assert_in_delta(pubdate, expected_pubdate, 1.second) if expected_pubdate
    pass
  end
end
