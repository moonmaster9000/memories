module Memories
  class Attachment
    def initialize(string)
      @string = string
    end

    def read; @string; end
  end
end
