require 'json'
require_relative 'har_utils'

module Akita
  class HttpRequest
    # Produces an HttpRequest from a request's HTTP environment.
    def initialize(env)
      req = Rack::Request.new env

      @self = {
        method: req.request_method,
        url: req.url,
        httpVersion: getHttpVersion(env),
        cookies: getCookies(env),
        headers: getHeaders(env),
        queryString: getQueryString(env),
        postData: getPostData(env),
        headersSize: -1,  # Doesn't appear to be available in env.
        bodySize: getBodySize(env),
      }
    end

    def to_json(*args)
      @self.to_json(*args)
    end

    # Obtains the client-requested HTTP version from an HTTP environment.
    def getHttpVersion(env)
      # XXX This isn't populated when running with `rspec`.
      env['HTTP_VERSION']
    end

    # Builds a list of cookie objects from an HTTP environment.
    def getCookies(env)
      req = Rack::Request::new env
      HarUtils.hashToList req.cookies
    end

    # Builds a list of headers from an HTTP environment.
    def getHeaders(env)
      # HTTP headers in the environment can be identified with the "HTTP_"
      # prefix. Filter for these. In the resulting map, rewrite keys of the
      # form "HTTP_FOO_BAR_BAZ" into "Foo-Bar-Baz", and convert into an array.
      HarUtils.hashToList (
        env.select { |k,v| k.start_with? 'HTTP_' }.
          transform_keys { |k|
            k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
          }
      )
    end

    # Builds a list of query parameters from an HTTP environment.
    def getQueryString(env)
      req = Rack::Request::new env
      paramMap = Rack::Utils.parse_nested_query req.query_string
      HarUtils.hashToList paramMap
    end

    # Obtains the posted data from an HTTP environment.
    def getPostData(env)
      if env.key?('CONTENT_TYPE') && env['CONTENT_TYPE'] then
        result = { mimeType: env['CONTENT_TYPE'] }

        # Populate 'params' if we have URL-encoded parameters. Otherwise,
        # populate 'text.
        req = Rack::Request.new env
        if env['CONTENT_TYPE'] == 'application/x-www-form-urlencoded' then
          # Decoded parameters can be found as a map in req.params. Convert
          # this map into an array.
          #
          # XXX Spec has space for files, but are file uploads ever
          # URL-encoded?
          result['params'] = HarUtils.hashToList req.params
        else
          result['text'] = req.body.string
        end

        result
      else
        nil
      end
    end

    # Obtains the size of the request body from an HTTP environment. Returns -1
    # if this cannot be determined.
    def getBodySize(env)
      env.key?('CONTENT_LENGTH') ? env['CONTENT_LENGTH'].to_i : -1
    end
  end
end
