module Memories
  class VersionsProxy #:nodoc
    def initialize(doc)
      @doc = doc
      @versions = {}
    end

    def count
      @doc.current_version
    end

    def [](arg)
      case arg.class.to_s
        when "Range" then version_range arg
        when "Fixnum" then version_num arg
        when "String" then version_id arg
        else raise "Invalid argument."
      end
    end

    private
    def version_range(range)
      return [] if range.first > @doc.current_version
      current_version = range.last >= @doc.current_version ? @doc.dup : nil
      last = range.last >= @doc.current_version ? @doc.current_version - 1 : range.last
      versions = (range.first..last).to_a.map {|i| version_num i}
      versions << current_version if current_version 
      versions
    end

    def version_num(num)
      return nil if !num.kind_of?(Fixnum) or num >= @doc.current_version or num < 1
      @versions[num] ||= @doc.dup.revert_to(num)
    end

    def version_id(id)
      version_num @doc.version_number(id)
    end
  end
end
