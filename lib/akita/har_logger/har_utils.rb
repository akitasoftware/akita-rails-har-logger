# frozen_string_literal: true

module Akita
  module HarLogger
    class HarUtils
      # Rack apparently uses 8-bit ASCII for everything, even when the string
      # is not 8-bit ASCII. This reinterprets 8-bit ASCII strings as UTF-8.
      def self.fixEncoding(v)
        if v == nil || v.encoding != Encoding::ASCII_8BIT then
          v
        else
          String.new(v).force_encoding(Encoding::UTF_8)
        end
      end

      # Converts a Hash into a list of Hash objects. Each entry in the given
      # Hash will be represented in the output by a Hash object that maps
      # 'name' to the entry's key and 'value' to the entry's value.
      def self.hashToList(hash)
        hash.reduce([]) { |accum, (k, v)|
          accum.append({
            name: fixEncoding(k),
            value: fixEncoding(v),
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
