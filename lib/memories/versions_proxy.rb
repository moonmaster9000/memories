module Memories
  class VersionsProxy
    # A Memories::VersionsProxy is automatically initialized, memoized, 
    # and returned when you call the `versions` method on your document.
    #   doc = Book.create :name => '2001'
    #   doc.versions.class # ==> ::Memories::VersionsProxy
    def initialize(doc)
      @doc = doc
      @versions = {}
    end
    
    # Returns the number of versions of your document.
    #   doc = Book.create :name => '2001'
    #   doc.name = '2001: A Space Odyssey'
    #   doc.save
    #   doc.versions.count # ==> 2
    def count
      @doc.current_version
    end

    # Returns the first version of your document
    #   doc = Book.create :name => '2001'
    #   doc.name = '2001: A Space Odyssey'
    #   doc.save
    #   doc.versions.first.name # ==> '2001'
    def first
      @doc.current_version == 1 ? @doc.dup : version_num(1)
    end

    # Returns the last version of your document (which should be the same as your document)    
    #   doc = Book.create :name => '2001'
    #   doc.name = '2001: A Space Odyssey'
    #   doc.save
    #   doc.versions.last.name # ==> '2001: A Space Odyssey'
    def last
      @doc.dup
    end

    # Provides array-like and hash-like access to the versions of your document.
    #   @doc.versions[1] # ==> returns version 1 of your document
    #   @doc.versions['rev-1-kjfdsla3289430289432'] # ==> returns version 1 of your document
    #   @doc.versions[5..20] # ==> returns versions 5 through 20 of your document
    #   @doc.versions.count # ==> returns the number of versions of your document
    #   @doc.versions.last # ==> returns the latest version of your document
    #   @doc.versions.first # ==> returns the first version of your document
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
      sanitize_range(range).to_a.map {|i| version_num i}
    end

    def version_num(num)
      return nil if !num.kind_of?(Fixnum) or num > @doc.current_version or num < 1
      @versions[num] ||= @doc.dup.revert_to(num)
    end

    def sanitize_range(range)
      raise StandardError, "Sorry, but we don't allow negative numbers in the range." if range.first < 0 or range.last < 0
      return [] if range.first > @doc.current_version
      first = [1, range.first].max
      last  = [range.last, @doc.current_version].min
      (first..last)
    end

    def version_id(id)
      version_num @doc.version_number(id)
    end
  end
end
