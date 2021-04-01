require 'json'
require_relative 'har_utils'

module Akita
  class HttpRequest
    # Produces an HttpRequest from a request's HTTP environment.
    def initialize(env)
      req = Rack::Request.new env

      @self = {
        method: getMethod(env),
        url: req.url,
        httpVersion: getHttpVersion(env),
        cookies: getCookies(env),
        headers: getHeaders(env),
        queryString: getQueryString(env),
        headersSize: getHeadersSize(env),
        bodySize: getBodySize(env),
      }

      # Augment with post data if we have any.
      postData = getPostData(env)
      if postData != nil then
        @self[:postData] = postData
      end
    end

    def to_json(*args)
      @self.to_json(*args)
    end

    # Obtains the client's request method from an HTTP environment.
    def getMethod(env)
      (Rack::Request.new env).request_method
    end

    # Obtains the client-requested HTTP version from an HTTP environment.
    def getHttpVersion(env)
      # The environment doesn't have HTTP_VERSION when running with `rspec`;
      # assume HTTP/1.1 when this happens. We don't return nil, so we can
      # calculate the size of the headers.
      env.key?('HTTP_VERSION') ? env['HTTP_VERSION'] : 'HTTP/1.1'
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
          result[:params] = HarUtils.hashToList req.params
        else
          result[:text] = req.body.string
        end

        result
      else
        nil
      end
    end

    def getHeadersSize(env)
      # XXX This seems to under-count, compared to a HAR produced by Firefox.

      # Count the number of bytes needed to produce the first line of the
      # request (HTTP method, full path, HTTP version, CRLF). For example,
      #
      #   GET /index.html?foo=bar&baz=qux HTTP/1.1<CR><LF>
      req = Rack::Request::new env
      line_length =
        getMethod(env).length + 1
          + req.fullpath.length + 1
          + getHttpVersion(env).length + 2

      # Add the size of the headers. Add 2 to the starting value to account for
      # the CRLF on the blank line.
      getHeaders(env).reduce(line_length + 2) { |accum, entry|
        # Header-Name: header value<CR><LF>
        accum + entry[:name].length + 2 + entry[:value].length + 2
      }
    end

    # Obtains the size of the request body from an HTTP environment.
    def getBodySize(env)
      # Assume no content if Content-Length header was not provided.
      env.key?('CONTENT_LENGTH') ? env['CONTENT_LENGTH'].to_i : 0
    end
  end
end
