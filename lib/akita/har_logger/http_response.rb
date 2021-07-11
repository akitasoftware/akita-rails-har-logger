# frozen_string_literal: true

require_relative 'har_utils'

module Akita
  module HarLogger
    class HttpResponse
      def initialize(env, status, headers, body)
        @self = {
          status: status,
          statusText: getStatusText(status),
          httpVersion: getHttpVersion(env),
          cookies: getCookies(headers),
          headers: (HarUtils.hashToList headers),
          content: getContent(headers, body),
          redirectURL: getRedirectUrl(headers),
          headersSize: getHeadersSize(env, status, headers),
          bodySize: getBodySize(body),
        }
      end

      def to_json(*args)
        @self.to_json(*args)
      end

      # Obtains the status text corresponding to a status code.
      def getStatusText(status)
        HarUtils.fixEncoding(Rack::Utils::HTTP_STATUS_CODES[status])
      end

      # Obtains the HTTP version in the response.
      def getHttpVersion(env)
        # XXX Assume the server replies with the same HTTP version as the
        # XXX request. This seems to hold true empirically.

        # The environment doesn't have HTTP_VERSION when running with `rspec`;
        # assume HTTP/1.1 when this happens. We don't return nil, so we can
        # calculate the size of the headers.
        env.key?('HTTP_VERSION') ?
          HarUtils.fixEncoding(env['HTTP_VERSION']) :
          'HTTP/1.1'
      end

      def getCookies(headers)
        result = []
        headers.each { |k, v|
          if "Set-Cookie".casecmp(k) != 0 then next end

          # Couldn't find a great library for parsing Set-Cookie headers, so
          # let's roll our own...
          #
          # According to RFC 6265, the value of Set-Cookie has the format
          # "cookieName=cookieValue", optionally followed by a semicolon and
          # attribute-value pairs. The cookieValue can be optionally enclosed
          # in double quotes. Neither cookieName nor cookieValue can contain
          # double quotes, semicolons, or equal signs.
          match = /^([^=]*)=([^;]*)(|;.*)$/.match(v)
          if !match then next end

          cookie_name = match[1]
          cookie_value = match[2]

          # Strip quotation marks from the value if they are present.
          match = /^"(.*)"$/.match(cookie_value)
          if match then cookie_value = match[1] end

          result << {
            name: HarUtils.fixEncoding(cookie_name),
            value: HarUtils.fixEncoding(cookie_value),
          }
        }

        result
      end

      def getContent(headers, body)
        # XXX Handle compression & encoding.

        text = +""
        body.each { |part|
          # XXX Figure out how to join together multi-part bodies.
          text << (HarUtils.fixEncoding part);
        }

        {
          size: getBodySize(body),

          # XXX What to use when no Content-Type is given?
          mimeType: HarUtils.fixEncoding(headers['Content-Type']),

          text: text,
        }
      end

      def getRedirectUrl(headers)
        # Use the "Location" header if it exists. Otherwise, based on some HAR
        # examples found online, it looks like an empty string is used.
        headers.key?('Location') ?
          HarUtils.fixEncoding(headers['Location']) :
          ''
      end

      def getHeadersSize(env, status, headers)
        # XXX This seems to under-count, compared to a HAR produced by Firefox.

        # Count the number of bytes needed to produce the first line of the
        # response (HTTP version, status code, status text, CRLF). For example,
        #
        #   HTTP/1.1 404 Not Found<CR><LF>
        status_length =
          getHttpVersion(env).length + 1
            + status.to_s.length + 1
            + getStatusText(status).length + 2

        # Add the size of the headers. Add 2 to the starting value to account
        # for the CRLF on the blank line.
        headers.reduce(status_length + 2) { |accum, (k, v)|
          # Header-Name: header value<CR><LF>
          accum + k.length + 2 + v.length + 2
        }
      end

      def getBodySize(body)
        length = 0
        body.each { |part| length += part.bytesize }
        length
      end
    end
  end
end
