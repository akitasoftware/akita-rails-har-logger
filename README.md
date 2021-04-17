# Akita HTTP Archive (HAR) logger for Rack/Rails applications

This provides Rack middleware and a Rails `ActionController` filter for logging
HTTP request–response pairs to a HAR file.


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

There are two options for instrumenting your Rack/Rails application. The first
is to use the HAR logger as Rack middleware. The second is to use it as a Rails
`ActionController` filter.

Depending on the framework you're using, one or both options may be available
to you. If you are interested in logging RSpec tests, the filter option will
capture traffic for both controller and request specs, whereas the middleware
option only captures request specs.

Once your application is instrumented, when you run the application, HTTP
requests and responses will be logged to the HAR file that you've specified.
You can then upload this HAR file to Akita for analysis.

### Middleware

To instrument with middleware, add `Akita::HarLogger::Middleware` to the top of
your middleware stack. For convenience, you can call
`Akita::HarLogger.instrument` to do this. We recommend adding this call to the
bottom of `config/environments/test.rb` to add the middleware just to your test
environment.

Here is a sample configuration for a test environment that just adds the
instrumentation.

```ruby
Rails.application.configure.do
  # Other configuration for the Rails application...

  # Put the HAR logger at the top of the middleware stack, and optionally
  # give an output HAR file to save your trace. If not specified, this defaults
  # to `akita_trace_{timestamp}.har`.
  Akita::HarLogger.instrument(config, "akita_trace.har")
end
```

### `ActionController` filter

To instrument with a filter, add an instance of `Akita::HarLogger::Filter` as
an `around_action` filter to your `ActionController` implementation. Here is an
example of a bare-bones `app/controllers/application_controller.rb` with this
instrumentation.

```ruby
class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler

  # Add the HAR logger as an `around_action` filter. Optionally give an output
  # HAR file to save your trace. If not specified, this defaults to
  # `akita_trace_{timestamp}.har`.
  around_action Akita::HarLogger::Filter.new("akita_trace.har")
end
```


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
