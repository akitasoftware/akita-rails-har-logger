# Akita HTTP Archive (HAR) logger for Rack applications

This provides Rack middleware for logging HTTP request–response pairs to a HAR
file.


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

To instrument your Rack application, add `Akita::HarLogger::Middleware` to the
top of your middleware stack. For convenience, you can use
`Akita::HarLogger.instrument`, as follows.

1. In your main `application.rb`, make `Akita::HarLogger` available:
    ```ruby
    require 'akita/har_logger'
    ```
2. Add the following line to the bottom of your `Rails::Application`
   subclass:
   ```ruby
   Akita::HarLogger.instrument(config, '/path/to/output/har_file.har')
   ```

Now, when you run your Rack application, all HTTP requests and responses will
be logged to the HAR file that you've specified. You can then upload this HAR
file to Akita for analysis.


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
