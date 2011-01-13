module Memories
  class VersionsProxy
    # A Memories::VersionsProxy is automatically initialized, memoized, 
    # and returned when you call the `versions` method on your document.
    #   doc = Book.create :name => '2001'
    #   doc.name = '2001: A Space Odyssey'
    #   doc.milestone!
    #   doc.versions.class # ==> ::Memories::VersionsProxy
    #
    # You can access versions by version number
    #   doc.versions[0] #==> nil
    #   doc.versions[1].revision #==> 'rev-1-io329uidlrew098320'
    #   doc.versions[1].instance.name #==> '2001'
    #   doc.versions[1].milestone? #==> false
    #   doc.versions[2].instance.name #==> '2001: A Space Odyssey'
    #   doc.versions[2].milestone? #==> true
    #   doc.versions[2].version_number # ==> 2
    #
    def initialize(doc)
      @doc = doc
      @versions = []
    end

    def count
      populate_proxies
      @versions.count - 1
    end

    def [](arg)
      populate_proxies
      
      if arg.kind_of?(String)
        @versions[@doc.version_number arg]
      else
        @versions[arg]
      end
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

    def revision
      version
    end

    def milestone?
      @is_milestone ||= @doc.milestones.collect(&:version).include? version
    end

    def instance
      @instance ||= @doc.dup.revert_to @version_number
    end
  end
end
