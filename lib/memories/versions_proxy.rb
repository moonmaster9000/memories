module Memories
  class VersionsProxy
    # A Memories::VersionsProxy is automatically initialized, memoized, 
    # and returned when you call the `versions` method on your document.
    #   doc = Book.create :name => '2001'
    #   doc.versions.class # ==> ::Memories::VersionsProxy
    def initialize(doc)
      @doc = doc
      @versions = []
    end

    def method_missing(method_name, *args, &block)
      populate_proxies
      @versions.send(method_name, *args, &block)
    end

    private
    def populate_proxies
      if (@versions.count - 1) < @doc.current_version.to_i
        (1..@doc.current_version.to_i).each do |i|
          @versions[i] ||= VersionProxy.new @doc, i
        end
      end
    end
  end

  class VersionProxy
    attr_reader :version_number

    def initialize(doc, version_number)
      @doc = doc
      @version_number = version_number
    end
    
    def version
      @version ||= @doc.version_id @version_number
    end

    def milestone?
      @is_milestone ||= @doc.milestones.collect(&:version).include? version
    end

    def instance
      @instance ||= @doc.dup.revert_to @version_number
    end
  end
end
