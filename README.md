# Akita::HarLogger

Rack middleware for logging HTTP request–response pairs to a HAR file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'akita-har_logger'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install akita-har_logger

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Implementation notes

References used when building this:
  * https://ieftimov.com/post/writing-rails-middleware/
  * https://github.com/rack/rack/blob/master/SPEC.rdoc
  * https://w3c.github.io/web-performance/specs/HAR/Overview.html
  * http://www.softwareishard.com/blog/har-12-spec/
