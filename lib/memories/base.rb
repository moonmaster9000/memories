module Memories
  def self.included(base)
    base.property(:milestone_memories) do |milestone_memory|
      milestone_memory.property :version, Fixnum
      milestone_memory.property :annotations, Memories::Annotation
    end

    base.before_update :add_version_attachment
    base.after_update :decode_attachments
  end
  
  VERSION_REGEX = /(?:rev-)?(\d+)-[a-zA-Z0-9]+/

  def revert_to!(version=nil)
    version ||= previous_version
    if (match = version.to_s.match(VERSION_REGEX)) && match[1]
      version = match[1].to_i  
    end
    
    if properties = JSON.parse(read_attachment(version_id version))
      self.update_attributes properties
    end
  end

  def revert_to_milestone!(n)
    self.revert_to! self.milestones[n.to_i-1].version
  end
  
  def version_id(version_num)
    self["_attachments"].keys.sort {|a,b| version_number(a) <=> version_number(b)}[version_num - 1] if self["_attachments"]
  end

  def version_number(version_id)
    version_id.gsub(VERSION_REGEX, '\1').to_i
  end

  def previous_version
    current_version - 1
  end

  def current_version
    version_number rev
  end

  def milestone!(&block)
    annotations = Memories::Annotation.new
    annotations.instance_eval(&block) if block
    self.milestone_memories << {:version => self.current_version, :annotations => annotations}
    self.save
  end

  def milestones
    self.milestone_memories
  end

  def latest_milestone
    self.milestone_memories.last
  end

  private
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
