module Memories
  class Attachment #:nodoc:
    def initialize(string)
      @string = string
    end

    def read; @string; end
  end
end
