# frozen_string_literal: true

require_relative 'har_logger/har_entry'
require_relative 'har_logger/version'
require_relative 'har_logger/writer_thread'

module Akita
  module HarLogger
    # Adds HAR-logging instrumentation to a Rails application by adding to the
    # top of the middleware stack.
    #
    # Params:
    # +config+:: the +Rails::Application::Configuration+ associated with the
    #            Rails application being instrumented.
    # +har_file_name:: the name of the HAR file to be produced. If the file
    #                  exists, it will be overwritten.
    def self.instrument(config, har_file_name = nil)
      config.middleware.unshift(Middleware, har_file_name)
    end

    # Logs HTTP request-response pairs to a HAR file.
    #
    # Params:
    # +app+:: the application to log.
    # +out_file_name+:: the name of the HAR file to be produced. If the file
    #                   exists, it will be overwritten.
    class Middleware
      def initialize(app, out_file_name = nil)
        @app = app

        if out_file_name == nil then
          out_file_name = HarLogger.default_file_name
        end

        @entry_queue = HarLogger.get_queue(out_file_name)
      rescue => e
        HarLogger.logException("initializing middleware", e)
        raise
      end

      def call(env)
        start_time = Time.now

        # Read the request body here, in case there is non-Rack-compliant
        # middleware in the stack that closes the request-body stream on us.
        request_body = env['rack.input'].read
        env['rack.input'].rewind  # Be kind.

        status, headers, body = @app.call(env)
        end_time = Time.now

        wait_time_ms = ((end_time.to_f - start_time.to_f) * 1000).round

        # Patch env with our saved request body.
        saved_input = env['rack.input']
        env['rack.input'] = StringIO.new request_body

        @entry_queue << (HarEntry.new start_time, wait_time_ms, env, status,
                                      headers, body)

        # Be kind and restore the original request-body stream.
        env['rack.input'] = saved_input

        [ status, headers, body ]
      rescue => e
        HarLogger.logException("handling request", e)
        raise
      end
    end

    # Logs the given exception.
    def self.logException(context, e)
      Rails.logger.debug "AKITA: Exception while #{context}: #{e.message} "\
                         "(#{e.class.name}) in thread #{Thread.current}"
      e.backtrace.each { |frame|
        Rails.logger.debug "AKITA:   #{frame}"
      }
    end

    # Logging filter for `ActionController`s.
    # TODO: Some amount of code duplication here. Should refactor.
    class Filter
      def initialize(out_file_name = nil)
        if out_file_name == nil then
          out_file_name = HarLogger.default_file_name
        end

        @entry_queue = HarLogger.get_queue(out_file_name)
      rescue => e
        HarLogger.logException("initializing filter", e)
        raise
      end

      # Registers an `on_load` initializer to add a logging filter to any
      # ActionController that is created.
      def self.install(out_file_name = nil, hook_name = :action_controller)
        ActiveSupport.on_load(hook_name) do
          around_action Filter.new(out_file_name)
        end
      end

      # Implements the actual `around` filter.
      def around(controller)
        start_time = Time.now

        # Read the request body here, in case there is non-Rack-compliant
        # middleware in the stack that closes the request-body stream on us.
        request_body = controller.response.request.env['rack.input'].read
        controller.response.request.env['rack.input'].rewind  # Be kind.

        yield

        end_time = Time.now
        wait_time_ms = ((end_time.to_f - start_time.to_f) * 1000).round

        response = controller.response
        request = response.request

        # Patch env with our saved request body.
        saved_input = request.env['rack.input']
        request.env['rack.input'] = StringIO.new request_body

        @entry_queue << (HarEntry.new start_time, wait_time_ms, request.env,
                                      response.status, response.headers,
                                      [response.body])

        # Be kind and restore the original request-body stream.
        request.env['rack.input'] = saved_input
      rescue => e
        HarLogger.logException("handling request", e)
        raise
      end
    end

    @@default_file_name = "akita_trace_#{Time.now.to_i}.har"
    def self.default_file_name
      @@default_file_name
    end

    # Maps the name of each output file to a queue of entries to be logged to
    # that file. The queue is used to ensure that event logging is thread-safe.
    # The main thread will enqueue HarEntry objects. A HAR writer thread
    # dequeues these objects and writes them to the output file.
    @@entry_queues = {}
    @@entry_queues_mutex = Mutex.new

    # Returns the entry queue for the given file. If an entry queue doesn't
    # already exist, one is created and a HAR writer thread is started for the
    # queue.
    def self.get_queue(out_file_name)
      queue = nil
      Rails.logger.debug "AKITA: About to acquire entry-queue mutex "\
                         "#{@@entry_queues_mutex} in #{Thread.current}. "\
                         "Self-owned? #{@@entry_queues_mutex.owned?}"
      @@entry_queues_mutex.synchronize {
        begin
          Rails.logger.debug "AKITA: Acquired entry-queue mutex "\
                             "#{@@entry_queues_mutex} in #{Thread.current}."
          if @@entry_queues.has_key?(out_file_name) then
            return @@entry_queues[out_file_name]
          end

          queue = Queue.new
          @@entry_queues[out_file_name] = queue
        ensure
          Rails.logger.debug "AKITA: About to release entry-queue mutex "\
                             "#{@@entry_queues_mutex} in #{Thread.current}."
        end
      }

      WriterThread.new out_file_name, queue
      return queue
    end
  end
end
