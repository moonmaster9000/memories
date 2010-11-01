module Memories
  class Attachment #:nodoc:
    def initialize(data)
      @data = data
    end

    def read; @data; end
  end
end
