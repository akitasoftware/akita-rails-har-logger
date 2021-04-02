# frozen_string_literal: true

require 'json'

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
          shutdown_mutex.synchronize {
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
          }
        end

        # Finish outputting the HAR file when the application shuts down.
        at_exit do
          # Signal to the consumer that this is the end of the entry stream and
          # wait for the consumer to terminate.
          entry_queue << nil
          shutdown_mutex.synchronize {}
        end
      end
    end
  end
end
