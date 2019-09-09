# frozen_string_literal: true

require 'webpage_pubdate/version'
require 'open-uri'
require 'nokogiri'
require 'active_support'
require 'active_support/all'
require 'active_support/time'
require 'httparty'

# howmuch
# reddit
# airtable
# https://visual.ly/community/infographic/sports/baseballs-many-physical-dimensions
# https://ourworldindata.org/does-the-news-reflect-what-we-die-from
# https://public.tableau.com/profile/jared.oeth5356#!/vizhome/FANTASYFOOTBALLFINISH/FANTASYFINISH
# https://interactives.cbinsights.com/us-banks-fintech-investments/
# https://www.marketingcharts.com/category/featured/page/2
# https://www.niemanlab.org/2019/02/heres-where-your-new-readers-are-going-to-come-from-in-2019/
# https://medium.com/google-news-lab
# bcg.com
# https://www.spglobal.com/marketintelligence/en/news-insights/research/outlook-for-2019-from-a-private-equity-point-of-view
# https://fivethirtyeight.com/features/do-we-even-need-minor-league-baseball/

module WebpagePubdate
  METAS = [
    { property: 'property', value: 'article:published_time' }, # SPEC OG
    { property: 'property', value: 'article:published' }, # NYT OG
    { property: 'name', value: 'article.published' },
    { property: 'property', value: 'bt:pubDate' },
    { property: 'name', value: 'DC.date.issued' },
    { property: 'property', value: 'pubdate' },
    { property: 'name', value: 'pubdate' },
    { property: 'name', value: 'parsely-pub-date' }
  ].freeze

  HEADERS = { 'pragma'          => 'no-cache',
              'cache-control'   => 'no-cache',
              'user-agent'      => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36',
              'accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
              'accept-language' => 'en-US,en;q=0.9,fr;q=0.8' }

  class WebpagePubdate
    def self.from_url(url)
      begin
        content = HTTParty.get(url, headers: HEADERS).body
        doc     = Nokogiri::HTML(content)
        WebpagePubdate.new(doc, url)
      rescue StandardError => e
        puts "fail to get #{e}"
      end
    end

    def self.from_nokogiri_doc(doc)
      WebpagePubdate.new(doc, nil)
    end

    def initialize(doc, url)
      @doc = doc
      @url = url
    end

    def pubdate(opts = {})
      tz       = ActiveSupport::TimeZone.new('UTC')
      @debug   = !!opts[:debug]
      @metas   = metas
      @json_ld = json_ld

      #
      # Try getting publication from <meta> tags
      #

      meta_pubdates = @metas.compact.map do |ds|
        m       = ds[:content].match(/^(\d\d\d\d)(\d\d)(\d\d)$/)
        pubdate = if m
                    year  = m[1]
                    month = m[2]
                    day   = m[3]
                    tz.iso8601("#{year}-#{month}-#{day}")
                  else
                    tz.parse(ds[:content])
                  end
        { meta: ds[:meta], pubdate: pubdate } if pubdate
      end.compact

      if @debug
        unless meta_pubdates.empty?
          puts "DEBUG: <meta> => #{meta_pubdates}"
        else
          puts "DEBUG: no meta"
        end
      end

      return meta_pubdates.first[:pubdate] unless meta_pubdates.empty?

      #
      # Try getting publication date from microformats
      #

      microformats_pubdate = microformats

      if @debug
        puts "DEBUG: #{microformats_pubdate ? 'HAS' : 'NO'} microformat publisher date"
      end

      return tz.parse(microformats_pubdate) if microformats_pubdate

      #
      #  Try getting publication date from JSON-LD
      #

      json_ld_pubdate = nested_hash_value(@json_ld, 'datePublished') || nested_hash_value(@json_ld, 'published')

      if @debug
        puts "DEBUG: #{@json_ld ? 'HAS ' : 'NO '} JSON-LD"
        puts "DEBUG: JSON-LD has pubdate" if json_ld_pubdate
      end

      return tz.parse(json_ld_pubdate) if json_ld_pubdate

      #
      # Last chance: from the url
      #

      url_pubdate = from_url

      if @debug
        puts "DEBUG: #{url_pubdate ? 'HAS ' : 'NO '} publication date in URL"
      end

      url_pubdate
    end

    def metas
      METAS.map do |meta|
        value = @doc.at("meta[#{meta[:property]}=\"#{meta[:value]}\"]")&.[]('content')
        { meta: "#{meta[:property]}_#{meta[:value]}}".to_sym, content: value } if value
      end.compact
    end

    def json_ld
      jsons = @doc.search('script[type="application/ld+json"]')
                .map(&:children)
                .map(&:to_s)
                .map { |str| str.gsub(/[[:space:]]+/, ' ').strip }
      jsons.reduce({}) do |accum, json|
        begin
          next unless json && json != ''
          ld = JSON.parse(json)
          next unless ld.is_a? Hash
          accum = accum.merge(ld)
        rescue JSON::JSONError => e
          puts e.to_s
          #        puts "xx#{json}xx"
        end
        accum
      end
    end

    def microformats
      pubdate = @doc.search('*[itemscope]')
                  .search('*[itemprop="datePublished"]')
                  .map { |node| node.attributes['datetime']&.value }
                  .compact
                  .first

      return pubdate if pubdate

      # some pages don't bother with itemscope
      @doc.search('*[itemprop="datePublished"]')
        .map { |node| node.attributes['datetime']&.value }
        .compact
        .first
    end

    def nested_hash_value(obj, key)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.respond_to?(:each)
        r = nil
        obj.find { |*a| r = nested_hash_value(a.last, key) }
        r
      end
    end

    def from_url
      return unless @url

      m = @url.match(/(\d\d\d\d)\/(\d\d?)\/(\d?\/)?$/)
      return unless m

      year  = m[1]
      month = m[2]
      day   = m[3] || '1'
      tz.iso8601("#{year}-#{month}-#{day}")
    end
  end
end
