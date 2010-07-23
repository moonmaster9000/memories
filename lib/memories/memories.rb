class CouchRest::Model::Base::Versioned < CouchRest::Model::Base
  class Attachment
    def initialize(string)
      @string = string
    end

    def read
      @string
    end
  end
 
  before_update :add_version_attachment

  def add_version_attachment
    current_version = Attachment.new self.database.get(self.id, :rev => self.rev).to_json
    self.create_attachment :file => current_version, :content_type => "application/json", :name => "rev-#{self.rev}"
  end
end
