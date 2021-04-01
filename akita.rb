require 'pp'
require_relative 'har_entry'
require_relative 'har_writer_thread'

module Akita
  # Middleware that logs HTTP request-response pairs to a HAR file.
  #
  # Params:
  # +app+:: the application to log.
  # +out_file_name+:: the name of the HAR file to be produced.
  class HarLoggerMiddleware
    def initialize(app, out_file_name)
      @app = app

      # This queue is used to ensure that event logging is thread-safe. The
      # main thread will enqueue HarEntry objects. The HAR writer thread below
      # dequeues these objects and writes them to the output file.
      @entry_queue = Queue.new
      HarWriterThread.new out_file_name, @entry_queue
    end

    def call(env)
      start_time = Time.now
      status, headers, body = @app.call(env)
      end_time = Time.now

      wait_time_ms = ((end_time.to_f - start_time.to_f) * 1000).round

      @entry_queue << (HarEntry.new start_time, wait_time_ms, env, status,
                                    headers, body)

      [ status, headers, body ]
    end
  end
end