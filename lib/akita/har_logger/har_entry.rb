# frozen_string_literal: true

require_relative 'http_request'
require_relative 'http_response'

module Akita
  module HarLogger
    # Encapsulates an HTTP request-response pair.
    class HarEntry
      attr_reader :request, :response

      # Params:
      # +start_time+:: a Time object representing the request's start time.
      # +env+:: the request's HTTP environment.
      # +status+:: the response's HTTP status code.
      # +headers+:: the response's HTTP headers.
      # +body+:: the response's HTTP body.
      def initialize(start_time, wait_time_ms, env, status, headers, body)
        @self = {
          startedDateTime: start_time.strftime('%FT%T.%L%:z'),
          time: wait_time_ms,
          request: (HttpRequest.new env),
          response: (HttpResponse.new env, status, headers, body),
          cache: {},  # Not applicable to server-side logging.
          timings: {
            send: 0,  # Mandatory, but not applicable to server-side logging.
            wait: wait_time_ms,
            receive: 0,  # Mandatory, but not applicable to server-side logging.
          },
        }
      end

      def to_json(*args)
        @self.to_json(*args)
      end
    end
  end
end
