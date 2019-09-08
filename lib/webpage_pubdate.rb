# frozen_string_literal: true

require 'webpage_pubdate/version'
require 'open-uri'
require 'nokogiri'
require 'active_support'
require 'active_support/all'
require 'active_support/time'

module WebpagePubdate
  METAS = [
    { property: 'property', value: 'article:published_time' }, # SPEC OG
    { property: 'property', value: 'article:published' },      # NYT OG
    { property: 'name', value: 'article.published' },
    { property: 'property', value: 'bt:pubDate' },
    { property: 'name', value: 'DC.date.issued' },
    { property: 'property', value: 'pubdate' },
    { property: 'name', value: 'pubdate' }
  ].freeze

  class WebpagePubdate
    def self.from_url(url)
      doc = Nokogiri::HTML(open(url).read)
      WebpagePubdate.new(doc, url)
    end

    def self.from_nokogiri_doc(doc)
      WebpagePubdate.new(doc, nil)
    end

    def initialize(doc, url)
      @doc = doc
      @url = url
    end

    def pubdate
      tz = ActiveSupport::TimeZone.new('UTC')
      @metas = metas
      @json_ld = json_ld

      meta_pubdates = @metas.compact.map do |ds|
        m = ds.match(/^(\d\d\d\d)(\d\d)(\d\d)$/)
        if m
          year = m[1].to_i
          month = m[2].to_i
          day = m[3].to_i
          # puts "#{year} #{month} #{day}"
          Time.zone.new(year, month, day)
        else
          tz.parse(ds)
        end
      end.compact

      # binding.pry if @url.match(/information/)

      return meta_pubdates.first unless meta_pubdates.empty?

      json_ld_pubdate = nested_hash_value(@json_ld, 'datePublished') || nested_hash_value(@json_ld, 'published')

      return tz.parse(json_ld_pubdate) if json_ld_pubdate

      # binding.pry
    end

    def metas
      METAS.map do |meta|
        @doc.at("meta[#{meta[:property]}=\"#{meta[:value]}\"]")&.[]('content')
      end.compact
    end

    def json_ld
      jsons = @doc.search('script[type="application/ld+json"]').map(&:children).map(&:to_s).map(&:strip)
      jsons.reduce({}) do |accum, json|
        begin
          accum = accum.merge(JSON.parse(json)) if json && json != ''
        rescue JSON::JSONError => e
          puts e.to_s
          #        puts "xx#{json}xx"
        end
        accum
      end
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
  end
end
