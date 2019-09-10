# WebpagePubdate

This gem attempts to glean the pulication date of a webpage.  It's inspired by (this article)[https://webhose.io/blog/api/articles-publication-date-extractor-an-overview/].

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webpage_pubdate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webpage_pubdate

## Usage

```ruby
pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate
```

It returns an `ActiveSupport::TimeWithZone`

You can enable some debug spew via:

```ruby
pubdate = WebpagePubdate::WebpagePubdate.from_url(url).pubdate({ debug: true })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To run the tests, run `bundle exec test`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iainbryson/webpage_pubdate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
