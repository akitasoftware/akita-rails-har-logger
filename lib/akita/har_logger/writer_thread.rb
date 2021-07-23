# frozen_string_literal: true

module Akita
  module HarLogger
    # A thread that consumes HarEntry objects from a queue and writes them to a
    # file.
    #
    # Params:
    # +out_file_name+:: the name of the HAR file to be produced.
    # +entry_queue+:: the queue from which to consume HAR entries.
    class WriterThread
      def initialize(out_file_name, entry_queue)
        # This mutex is used to ensure the entire output is written before the
        # application shuts down.
        shutdown_mutex = Mutex.new

        Thread.new do
          Rails.logger.debug "AKITA: About to acquire shutdown mutex "\
                             "#{shutdown_mutex} for file #{out_file_name} "\
                             "in writer thread #{Thread.current}. "\
                             "Self-owned? #{shutdown_mutex.owned?}"
          shutdown_mutex.synchronize {
            begin
              Rails.logger.debug "AKITA: Acquired shutdown mutex "\
                                 "#{shutdown_mutex} for file "\
                                 "#{out_file_name} in writer thread "\
                                 "#{Thread.current}."
              File.open(out_file_name, 'w') { |f|
                # Produce a preamble.
                f.write <<~EOF.chomp
                  {
                    "log": {
                      "version": "1.2",
                      "creator": {
                        "name": "Akita HAR logger for Ruby",
                        "version": "1.0.0"
                      },
                      "entries": [
                EOF

                first_entry = true

                loop do
                  entry = entry_queue.pop
                  if entry == nil then break end

                  # Emit comma separator if needed.
                  f.puts (first_entry ? '' : ',')
                  first_entry = false

                  # Emit the dequeued entry.
                  f.write JSON.generate(entry)
                end

                # Produce the epilogue.
                f.write <<~EOF

                      ]
                    }
                  }
                EOF
              }
            ensure
              Rails.logger.debug "AKITA: About to release shutdown mutex "\
                                 "#{shutdown_mutex} for file "\
                                 "#{out_file_name} in writer thread "\
                                 "#{Thread.current}."
            end
          }
        end

        # Finish outputting the HAR file when the application shuts down.
        at_exit do
          # Signal to the consumer that this is the end of the entry stream and
          # wait for the consumer to terminate.
          entry_queue << nil
          Rails.logger.debug "AKITA: About to acquire shutdown mutex "\
                             "#{shutdown_mutex} for file #{out_file_name} "\
                             "while shutting down in #{Thread.current}. "\
                             "Self-owned? #{shutdown_mutex.owned?}"
          shutdown_mutex.synchronize {
            Rails.logger.debug "AKITA: Acquired shutdown mutex "\
                               "#{shutdown_mutex} for file #{out_file_name} "\
                               "while shutting down in #{Thread.current}."
            Rails.logger.debug "AKITA: About to release shutdown mutex "\
                               "#{shutdown_mutex} for file #{out_file_name} "\
                               "while shutting down in #{Thread.current}."
          }
        end
      end
    end
  end
end
