module Akita
  class HarUtils
    # Converts a Hash into a list of Hash objects. Each entry in the given Hash
    # will be represented in the output by a Hash object that maps 'name' to
    # the entry's key and 'value' to the entry's value.
    def self.hashToList(hash)
      hash.reduce([]) { |accum, (k, v)|
        accum.append({
          name: k,
          value: v,
        })
      }
    end
  end
end
