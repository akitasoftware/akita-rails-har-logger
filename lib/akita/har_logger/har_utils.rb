# frozen_string_literal: true

module Akita
  module HarLogger
    class HarUtils
      # Rack apparently uses 8-bit ASCII for everything, even when the string
      # is not 8-bit ASCII. This reinterprets 8-bit ASCII strings as UTF-8.
      #
      # If we are unable to do this reinterpretation, return the string
      # unchanged, but log a warning that points to the caller.
      def self.fixEncoding(v)
        if v == nil then
          return v
        end

        if !(v.is_a? String) then
          Rails.logger.warn "[#{caller_locations(1, 1)}] fixEncoding was not given a string. This might cause JSON serialization to fail."
          return v
        end

        # Only re-interpret 8-bit ASCII.
        if v.encoding != Encoding::ASCII_8BIT then
          return v
        end

        forced = String.new(v).force_encoding(Encoding::UTF_8)
        if forced.valid_encoding? then
          return forced
        end

        Rails.logger.warn "[#{caller_locations(1, 1)}] Unable to fix encoding: not a valid UTF-8 string. This will likely cause JSON serialization to fail."
        v
      end

      # Converts a Hash into a list of Hash objects. Each entry in the given
      # Hash will be represented in the output by a Hash object that maps
      # 'name' to the entry's key and 'value' to the entry's value.
      def self.hashToList(hash)
        hash.reduce([]) { |accum, (k, v)|
          accum.append({
            name: fixEncoding(k),
            value: fixEncoding(v.to_s),
          })
        }
      end

      # Determines whether all values in a Hash are strings.
      def self.allValuesAreStrings(hash)
        hash.each do |_, value|
          if !(value.is_a? String) then
            return false
          end
        end

        return true
      end
    end
  end
end
