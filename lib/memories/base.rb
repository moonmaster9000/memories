# Simply "include Memories" in your CouchRest::Model::Base derived classes to add versioning to your document.
module Memories
  def self.included(base)
    base.property(:milestone_memories) do |milestone_memory|
      milestone_memory.property :version
      milestone_memory.property :annotations, 
        Memories::Annotation, 
        :init_method => proc { |value| 
          a = Memories::Annotation.new
          value.keys.each do |key|
            a.send key, value[key]
          end
          a
        }
    end

    base.before_update :add_version_attachment
    base.after_save :decode_attachments
    base.send :extend, ClassMethods
    base.alias_method_chain :save, :destroying_logical_version_and_revision
    base.alias_method_chain :save!, :destroying_logical_version_and_revision
  end
  
  module ClassMethods #:nodoc: all
    # If you'd like to exclude certain properties from versioning, simply pass those properties
    # to this method: 
    #   
    #   class MyDocument < CouchRest::Model::Base
    #     use_database MY_DATABASE
    #     include Memories
    #
    #     forget :prop1, :prop2
    #
    #     property :prop1 #not versioned
    #     property :prop2 #not versioned
    #     property :prop3 #versioned
    #   end
    def forget(*props) #:doc:
      raise StandardError, "Ambiguous use of both #remember and #forget." if @remember_called
      @forget_called = true
      self.forget_properties += props.map {|p| p.to_s}
    end


    # If you'd like to explicitly define which properties you want versioned simply pass those properties
    # to this method: 
    #   
    #   class MyDocument < CouchRest::Model::Base
    #     use_database MY_DATABASE
    #     include Memories
    #
    #     remember :prop1, :prop2
    #
    #     property :prop1 #versioned
    #     property :prop2 #versioned
    #     property :prop3 # not versioned
    #   end
    def remember(*props) #:doc:
      raise StandardError, "Ambiguous use of both #remember and #forget." if @forget_called
      @remember_called = true
      props = props.map {|p| p.to_s}
      if self.remember_properties.nil?
        self.remember_properties = props 
      else
        self.remember_properties += props 
      end
    end 

    # Returns true if self is set up to remember attachments. False otherwise.
    def remember_attachments? #:doc:
      @remember_attachments ? true : false
    end

    # Returns a list of attachment patterns for versioning. The list may contain
    # strings, denoting the names of attachments to version, but it may 
    # also contain regular expressions, indicating that attachments
    # with matching names should be versioned.
    def remember_attachments; @remember_attachments || []; end

    # If you'd like to version attachments, simply call this macro in your 
    # class definition: 
    #
    #   class MyDoc < CouchRest::Model::Base
    #     use_database MY_DB
    #     include Memories
    # 
    #     remember_attachments!
    #   end
    #
    # If you only want specific attachments versioned, pass 
    # strings and/or regular expressions to this macro. Any attachments
    # with matching names will be versioned.
    #
    #   class HtmlPage < CouchRest::Model::Base
    #     use_database MY_DB
    #     include Memories
    # 
    #     remember_attachments! "image.png", %r{stylesheets/.*}
    #   end
    #
    def remember_attachments!(*attachment_names) #:doc:
      if attachment_names.empty?
        @remember_attachments = [/.*/]
      else 
        @remember_attachments = attachment_names
      end
    end

    def remember_properties
      @remember_properties ||= nil
    end

    def remember_properties=(props)
      @remember_properties = props
    end

    def forget_properties
      @forget_properties ||= ["couchrest-type", "_id", "_rev", "_attachments", "milestone_memories"]
    end

    def forget_properties=(props)
      @forget_properties = props
    end
  end
   
  VERSION_REGEX = /(?:rev-)?(\d+)-[a-zA-Z0-9]+/ #:nodoc:
  
  # Returns a list of attachments it should remember.
  def attachments_to_remember
    return [] unless self.class.remember_attachments?
    (self.database.get(self.id)["_attachments"] || {}).keys.reject do |a| 
      a.match(VERSION_REGEX) || 
        !(self.class.remember_attachments.map { |attachment_name_pattern|
          a.match attachment_name_pattern
        }.inject(false) {|b, sum| sum || b})
    end 
  end

  # Returns a list of attachments it should not version
  def attachments_to_forget
    return [] unless self.class.remember_attachments?
    (self.database.get(self.id)["_attachments"] || {}).keys.reject do |a| 
      a.match(VERSION_REGEX) || 
        (self.class.remember_attachments.map { |attachment_name_pattern|
          a.match attachment_name_pattern
        }.inject(false) {|b, sum| sum || b})
    end 
  end
  
  # Revert the document to a specific version and save. 
  # You can provide either a complete revision number ("1-u54abz3948302sjjej3jej300rj", or "rev-1-u54abz3948302sjjej3jej300rj")
  # or simply a number (e.g, 1, 4, 100, etc.).
  #   my_doc.revert_to! 3 # ==> would revert your document "my_doc" to version 3. 
  def revert_to!(version)
    revert version, :hard
    self
  end

  # Same as #revert_to!, except that it doesn't save.
  def revert_to(version)
    revert version
    self
  end

  # Same as #rollback!, but doesn't save.
  def rollback
    self.revert_to self.previous_version
  end

  # Revert to the previous version, and resave the document. Shortcut for:
  #   my_doc.revert_to! my_doc.previous_version
  def rollback!
    self.revert_to! self.previous_version
  end

  # Revert to a given milestone and save. Milestones are stored in the .milestones array.
  # Reverting to milestone "n" reverts to milestone represented in the nth element in the 
  # milestones array.
  def revert_to_milestone!(n)
    verify_milestone_exists n
    self.revert_to! self.milestones[n.to_i-1].version
  end
 
  # Same as #revert_to_milestone!, except it doesn't save.
  def revert_to_milestone(n)
    verify_milestone_exists n
    self.revert_to self.milestones[n.to_i-1].version
  end
 
  # Same as #rollback_to_latest_milestone, but doesn't save. 
  def rollback_to_latest_milestone
    self.revert_to_milestone self.milestones.count
  end

  # Reverts to the latest milestone. Shortcut for:
  #   my_doc.revert_to_milestone! my_doc.milestones.count
  def rollback_to_latest_milestone!
    self.revert_to_milestone! self.milestones.count
  end
 
  # Retrieve the entire revision number, given an integer. 
  # For example, suppose my doc has 5 versions. 
  #   my_doc.version_id 4 #==> "rev-4-74fj838r838fhjkdfklasdjrieu4839493"
  def version_id(version_num)
    self["_attachments"].keys.select {|a| a.match /^rev-#{version_num}-.*$/}.first if self["_attachments"]
  end

  # Retrieve the version number, given a revision id. 
  # For example,
  #   my_doc.version_number "rev-5-kjfldsjaiu932489023rewar" #==> 5
  #   my_doc.version_number "4-jkfldsjli3290843029irelajfldsa" # ==> 4
  def version_number(version_id)
    version_id.gsub(VERSION_REGEX, '\1').to_i
  end

  # Shortcut for:
  #   my_doc.current_version - 1
  def previous_version
    current_version - 1
  end

  # Returns a simple version number (integer) corresponding to the current revision. 
  # For example, suppose the current revision (_rev) is: "4-jkfdlsi9432943wklrejwalr94302". 
  #   my_doc.current_version #==> 4
  def current_version
    version_number rev
  end

  # Provides array-like and hash-like access to the versions of your document.
  #   @doc.versions[1] # ==> returns version 1 of your document
  #   @doc.versions['rev-1-kjfdsla3289430289432'] # ==> returns version 1 of your document
  #   @doc.versions[5..20] # ==> returns versions 5 through 20 of your document
  #   @doc.versions.count # ==> returns the number of versions of your document
  #   @doc.versions.last # ==> returns the latest version of your document
  #   @doc.versions.first # ==> returns the first version of your document
  def versions
    @versions ||= VersionsProxy.new self
  end

  # Flag the current version as a milestone. You can optionally annotate the milestone by passing a do block to the method.
  #   some_article.milestone! do
  #     notes "Passed first round of editing."
  #     approved_by "Joe the editor."
  #   end
  # 
  # You may annotate with whatever properties you desire. "notes" and "approved_by" were simply examples.
  def milestone!(&block)
    annotations = Memories::Annotation.new
    annotations.instance_eval(&block) if block
    self.milestone_memories << {:version => self.rev, :annotations => annotations.to_hash}
    self.save
  end

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
  def milestones
    @milestones_proxy ||= MilestonesProxy.new self
  end

  # Returns the metadata (version, annotations) for the latest milestone created.
  def latest_milestone
    self.milestones.last
  end

  # Returns true if this instance represents a milestone
  def milestone?
    self.milestones.collect(&:version_number).include? self.logical_version_number
  end

  # Returns true if this instance is the version made right after a milestone, to denote the previous version as a milestone.
  def milestone_commit?
    self.milestones.collect(&:version_number).include? self.logical_version_number - 1
  end

  # When you soft revert a document, you can ask what the logical revision of it is.
  # For example, suppose you soft revert a document with 10 versions to version 2. 
  #     @doc.revert_to 2
  # When you ask the logical revision, you'll receive the revision number of version 2:
  #     @doc.logical_revision #==> 'rev-2-kfdlsa432890432890432'
  # However, as soon as you save the document, the logical_revision will simply mirror the actual revision
  #     @doc.save
  #     @doc.rev #==> '11-qwerty1234567890'
  #     @doc.logical_revision #==> 'rev-11-qwerty1234567890'
  def logical_revision
    @logical_revision || "rev-" + self.rev 
  end

  # When you soft revert a document, you can ask what the logical version number of it is.
  # For example, suppose you soft revert a document with 10 versions to version 2. 
  #   @doc.revert_to 2
  # When you ask the logical version number, you'll receive 2:
  #   @doc.logical_version_number #==> 2
  # However, as soon as you save the document, the logical_revision will simply mirror the actual revision
  #   @doc.save
  #   @doc.current_version #==> 11
  #   @doc.logical_version_number #==> 11
  def logical_version_number
    @logical_version_number || self.current_version
  end

  def save_with_destroying_logical_version_and_revision
    @logical_version_number = nil
    @logical_revision = nil
    save_without_destroying_logical_version_and_revision
  end

  def save_with_destroying_logical_version_and_revision!
    @logical_version_number = nil
    @logical_revision = nil
    save_without_destroying_logical_version_and_revision!
  end


  private
  def verify_milestone_exists(n)
    raise StandardError, "This document does not have any milestones." if self.milestones.empty?
    raise StandardError, "Unknown milestone" if n > self.milestones.count
  end

  def revert(version, revert_type = :soft)
    raise StandardError, "Unknown revert type passed to 'revert' method. Allowed types: :soft, :hard." if revert_type != :soft && revert_type != :hard
   
    if (match = version.to_s.match(VERSION_REGEX)) && match[1]
      version = match[1].to_i  
    end

    raise StandardError, "Unknown version" unless version.kind_of?(Fixnum)
    raise StandardError, "The requested version does not exist" if version < 1 or version > current_version
    return self if version == current_version
    
    if properties = JSON.parse(self.read_attachment(version_id version))
      revert_attachments properties
      self.update_attributes_without_saving properties
      overwrite_timestamp(properties)
      @logical_version_number = version
      @logical_revision = self.version_id version
      self.save if revert_type == :hard
    end
  end

  def revert_attachments(properties)
    if versioned_attachments = properties.delete('attachment_memories')
      versioned_attachments['versioned_attachments'].each do |name, attrs|
        attachment = { :name => name, :content_type => attrs['content_type'], :file => Attachment.new(Base64.decode64(attrs['data']))}
        has_attachment?(name) ? self.update_attachment(attachment) : self.create_attachment(attachment)
      end

      self["_attachments"].keys.select {|a| !a.match(VERSION_REGEX)}.each do |attachment|
        self.delete_attachment(attachment) if !versioned_attachments['known_attachments'].include?(attachment) and !attachments_to_forget.include?(attachment)
      end
    end
  end

  def add_version_attachment
    current_document_version = Attachment.new prep_for_versioning(self.database.get(self.id)).to_json
   
    self.create_attachment( 
      :file => current_document_version, 
      :content_type => "application/json", 
      :name => "rev-#{self.rev}"
    )
  end

  def prep_for_versioning(doc)
    versioned_doc = doc.dup
    add_attachment_memories versioned_doc if self.class.remember_attachments?
    strip_unversioned_properties versioned_doc
    versioned_doc
  end
  
  def add_attachment_memories(doc)
    doc['attachment_memories'] = {
      'versioned_attachments' => base64_encoded_attachments_to_remember(doc),
      'known_attachments' => (self.database.get(self.id, :rev => self.rev)["_attachments"] || {}).keys.select {|a| !a.match(VERSION_REGEX)}
    }
  end

  def base64_encoded_attachments_to_remember(doc)
    encoded_attachments = {}
    attachments_to_remember.each do |a|
      attachment_data = self.read_attachment(a) rescue nil
      if attachment_data
        encoded_attachments[a] = { 
          :content_type => doc['_attachments'][a]['content_type'],
          :data => Base64.encode64(attachment_data).gsub(/\s/, '')
        }
      end
    end
    encoded_attachments
  end

  def strip_unversioned_properties(doc)
    if self.class.remember_properties.nil?
      doc.delete_if {|k,v| self.class.forget_properties.include? k}
    else
      doc.delete_if {|k,v| !self.class.remember_properties.include?(k)}
    end   
  end

  # why is this necessary? Because couchrest destructively base64 encodes all attachments in your document. 
  def decode_attachments
    self["_attachments"].each do |attachment_id, attachment_properties|
      self["_attachments"][attachment_id]["data"] = Base64.decode64 attachment_properties["data"] if attachment_properties["data"] 
    end if self["_attachments"]
  end
  
  def overwrite_timestamp(properties)
    timestamp = 'updated_at'
    write_attribute(timestamp, Time.parse(properties[timestamp])) if properties.keys.include?(timestamp)
  end
  
end
