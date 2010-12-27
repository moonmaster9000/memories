# Simply "include Memories" in your CouchRest::Model::Base derived classes to add versioning to your document.
module Memories
  def self.included(base)
    base.property(:milestone_memories) do |milestone_memory|
      milestone_memory.property :version
      milestone_memory.property :annotations, Memories::Annotation
    end

    base.before_update :add_version_attachment
    base.after_save :decode_attachments
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
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
    def forget(*props)
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
    def remember(*props)
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
    def remember_attachments?
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
    def remember_attachments!(*attachment_names)
      if attachment_names.empty?
        @remember_attachments = [/.*/]
      else 
        @remember_attachments = attachment_names
      end
    end

    def remember_properties #:nodoc
      @remember_properties ||= nil
    end

    def remember_properties=(props) #:nodoc
      @remember_properties = props
    end

    def forget_properties #:nodoc:
      @forget_properties ||= ["couchrest-type", "_id", "_rev", "_attachments", "milestone_memories"]
    end

    def forget_properties=(props) #:nodoc:
      @forget_properties = props
    end
  end
  
  VERSION_REGEX = /(?:rev-)?(\d+)-[a-zA-Z0-9]+/
  
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
    self.milestone_memories << {:version => self.rev, :annotations => annotations}
    self.save
  end

  # returns an array of all milestones. Each milestone contains a "version" property (pointing to a specific revision)
  # and an "annotations" property, containing a (possibly empty) hash of key/value pairs corresponding to any annotations
  # the creator of the milestone decided to write.
  def milestones
    self.milestone_memories
  end

  # Returns the metadata (version, annotations) for the latest milestone created.
  def latest_milestone
    self.milestone_memories.last
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
    
    if properties = JSON.parse(self.read_attachment(version_id version))
      revert_attachments properties
      self.update_attributes_without_saving properties
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
end
