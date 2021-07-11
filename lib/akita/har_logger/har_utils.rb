# frozen_string_literal: true

module Akita
  module HarLogger
    class HarUtils
      # Rack apparently uses 8-bit ASCII for everything, even when the string
      # is not 8-bit ASCII. This reinterprets the given string as the default
      # external encoding and re-encodes into the default internal encoding.
      def self.fixEncoding(v)
        if v != nil then
          v.encode(Encoding.default_internal, Encoding.default_external)
        else
          nil
        end
      end

      # Converts a Hash into a list of Hash objects. Each entry in the given
      # Hash will be represented in the output by a Hash object that maps
      # 'name' to the entry's key and 'value' to the entry's value.
      def self.hashToList(hash)
        hash.reduce([]) { |accum, (k, v)|

          accum.append({
            name: k,
            value: v,
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
