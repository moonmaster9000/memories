module Memories
  #As of version 0.2.0, Memories also supports milestones. Milestones are special versions that you want to flag in some way.
  #For example, suppose you were creating a content management system, and every time someone publishes an article to the website, you want to flag the version
  #they published as a milestone. 
  #
  #    class Article < CouchRest::Model::Base
  #      include Memories
  #      use_database SOME_DATABASE
  #      
  #      property :title
  #      property :author
  #      property :body
  #
  #      def publish!
  #        # .... publishing logic
  #      end
  #    end
  #
  #    a = Article.create(
  #      :title => "Memories gem makes versioning simple", 
  #      :author => "moonmaster9000", 
  #      :body => <<-ARTICLE
  #        Check it out at http://github.com/moonmaster9000/memories
  #      ARTICLE
  #    )
  #    a.save
  #    a.publish!
  #    a.current_version #==> 1 
  #    a.milestone! do
  #      name "First publish."
  #      notes "Passed all relevant editing. Signed off by moonmaster10000"
  #    end
  #
  #Notice that we annotated our milestone; we gave it a name, and some notes. You can annotate with whatever properties you desire. The annotation do block is entirely optional.
  #Now that we've created a milestone, let's inspect it via the `milestones` array: 
  #
  #    a.milestones.count #==> 1
  #    a.milestones.last.version # ==> 1
  #    a.milestones.last.version # ==> 1
  #    a.milestones.last.annotations.name ==> "First publish."
  #    a.milestones.last.annotations.notes ==> "Passed all relevant editing. Signed off by moonmaster10000"
  #
  #Now, let's imagine that we've made some more edits / saves to the document, but they don't get approved. Now we want to revert to the version the document was
  #at at the first milestone. How do we do that? Simple!
  #
  #    a.revert_to_milestone! 1
  #
  #And now our document properties are back to the where they were when we first published the document.
  #
  #If you want to access the data from a milestone, simply use the "data" method: 
  #    
  #    a.milestones.first.data.title #==> returns the "title" attribute on the first milestone
  #    a.milestones.each do |m|
  #      puts "Version: " + m.version
  #      puts "Title: " + m.data.title
  #    end
  class MilestonesProxy
    def initialize(doc)
      @doc = doc
      @milestone_proxies = []
    end
    
    def method_missing(method_name, *args, &block)
      populate_proxies
      @milestone_proxies.send(method_name, *args, &block)
    end

    private
    def populate_proxies
      if @milestone_proxies.count < @doc.milestone_memories.count
        (@milestone_proxies.count...@doc.milestone_memories.count).each do |i|
          @milestone_proxies[i] = MilestoneProxy.new @doc, @doc.milestone_memories[i]
        end
      end
    end
  end

  class MilestoneProxy
    def initialize(doc, milestone_metadata)
      @doc = doc
      @milestone_metadata = milestone_metadata
      @version_number = @doc.version_number @milestone_metadata.version
    end

    def instance
      @instance ||= @doc.versions[@version_number].instance
    end

    def method_missing(method_name, *args, &block)
      @milestone_metadata.send method_name, *args, &block
    end
  end
end
