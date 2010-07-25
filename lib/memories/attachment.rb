module CouchRest
  module Model
    module Versioned
      class Attachment
        def initialize(string)
          @string = string
        end

        def read; @string; end
      end
    end
  end
end
