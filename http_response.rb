require 'json'

module Akita
  class HttpResponse
    def initialize(status, headers, body)
      @self = {
        # TODO
      }
    end

    def to_json(*args)
      @self.to_json(*args)
    end
  end
end
