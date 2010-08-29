# Simply "include Memories" in your CouchRest::Model::Base derived classes to add versioning to your document.
module Memories
  def self.included(base)
    base.property(:milestone_memories) do |milestone_memory|
      milestone_memory.property :version
      milestone_memory.property :annotations, Memories::Annotation
    end

    base.before_update :add_version_attachment
    base.after_update :decode_attachments
  end
  
  VERSION_REGEX = /(?:rev-)?(\d+)-[a-zA-Z0-9]+/
  
  # Revert the document to a specific version and save. 
  # You can provide either a complete revision number ("1-u54abz3948302sjjej3jej300rj", or "rev-1-u54abz3948302sjjej3jej300rj")
  # or simply a number (e.g, 1, 4, 100, etc.).
  #   my_doc.revert_to! 3 # ==> would revert your document "my_doc" to version 3. 
  def revert_to!(version)
    revert version, :hard
  end

  # Same as #revert_to!, except that it doesn't save.
  def revert_to(version)
    revert version
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
    self["_attachments"].keys.sort {|a,b| version_number(a) <=> version_number(b)}[version_num - 1] if self["_attachments"]
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
  # and an "annotations" property, containing a (possible empty) hash of key/value pairs corresponding to any annotations
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
    
    if properties = JSON.parse(read_attachment(version_id version))
      if revert_type == :soft
        self.update_attributes_without_saving properties
      elsif revert_type == :hard
        self.update_attributes properties
      end
    end
  end

  def add_version_attachment
    current_document_version = Attachment.new prep_for_versioning(self.database.get(self.id, :rev => self.rev)).to_json
    
    self.create_attachment( 
      :file => current_document_version, 
      :content_type => "application/json", 
      :name => "rev-#{self.rev}"
    )
  end

  def prep_for_versioning(doc)
    doc.dup.delete_if {|k,v| ["couchrest-type", "_id", "_rev", "_attachments", "milestone_memories"].include? k}
  end

  def decode_attachments
    self["_attachments"].each do |attachment_id, attachment_properties|
      attachment_properties["data"] = Base64.decode64 attachment_properties["data"] if attachment_properties["data"] 
    end
  end
end
