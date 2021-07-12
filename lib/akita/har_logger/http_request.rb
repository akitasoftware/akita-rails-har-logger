# frozen_string_literal: true

require_relative 'har_utils'

module Akita
  module HarLogger
    class HttpRequest
      # Produces an HttpRequest from a request's HTTP environment.
      def initialize(env)
        req = Rack::Request.new env

        @self = {
          method: getMethod(env),
          url: HarUtils.fixEncoding(req.url),
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
        HarUtils.fixEncoding (Rack::Request.new env).request_method
      end

      # Obtains the client-requested HTTP version from an HTTP environment.
      def getHttpVersion(env)
        # The environment doesn't have HTTP_VERSION when running with `rspec`;
        # assume HTTP/1.1 when this happens. We don't return nil, so we can
        # calculate the size of the headers.
        env.key?('HTTP_VERSION') ?
          HarUtils.fixEncoding(env['HTTP_VERSION']) :
          'HTTP/1.1'
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
        # form "HTTP_FOO_BAR_BAZ" into "Foo-Bar-Baz", and convert into an
        # array.
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

      # Obtains the character set of the posted data from an HTTP environment.
      def getPostDataCharSet(env)
        req = Rack::Request.new env
        if req.content_charset != nil then
          return req.content_charset
        end

        # RFC 2616 says that "text/*" defaults to ISO-8859-1.
        if env['CONTENT_TYPE'].start_with?('text/') then
          return Encoding::ISO_8859_1
        end

        Encoding::ASCII_8BIT
      end

      # Obtains the posted data from an HTTP environment.
      def getPostData(env)
        if env.key?('CONTENT_TYPE') && env['CONTENT_TYPE'] then
          result = { mimeType: env['CONTENT_TYPE'] }

          # Populate 'params' if we have URL-encoded parameters. Otherwise,
          # populate 'text'.
          req = Rack::Request.new env
          if env['CONTENT_TYPE'] == 'application/x-www-form-urlencoded' then
            # Decoded parameters can be found as a map in req.params.
            #
            # Requests originating from specs can be malformed: the values in
            # req.params are not necessarily strings. Encode all of req.params
            # in JSON and pretend the content type was "application/json".
            if HarUtils.allValuesAreStrings req.params then
              # Convert req.params into an array.
              #
              # XXX Spec has space for files, but are file uploads ever
              # URL-encoded?
              result[:params] = HarUtils.hashToList req.params
            else
              result[:mimeType] = 'application/json'
              result[:text] = req.params.to_json
            end
          else
            # Rack has been observed to use ASCII-8BIT encoding for the request
            # body when the request specifies UTF-8. Reinterpret the content
            # body according to what the request says it is, and re-encode into
            # UTF-8.
            #
            # Gracefully handle any characters that are invalid in the source
            # encoding and characters that have no UTF-8 representation by
            # replacing with '?'. Log a warning when this happens.
            source = req.body.string.force_encoding(getPostDataCharSet(env))
            utf8EncodingSuccessful = false
            if source.valid_encoding? then
              begin
                result[:text] = source.encode(Encoding::UTF_8)
                utf8EncodingSuccessful = true
              rescue Encoding::UndefinedConversionError
                Rails.logger.warn "[#{caller_locations(0, 1)}] Unable to losslessly convert request body from #{source.encoding} to UTF-8. Characters undefined in UTF-8 will be replaced with '?'."
              end
            else
              Rails.logger.warn "[#{caller_locations(0, 1)}] Request body is not valid #{source.encoding}. Invalid characters and characters undefined in UTF-8 will be replaced with '?'."
            end

            if !utf8EncodingSuccessful then
              result[:text] = source.encode(Encoding::UTF_8,
                  invalid: :replace, undef: :replace, replace: '?')
            end
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

        # Add the size of the headers. Add 2 to the starting value to account
        # for the CRLF on the blank line.
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
end
