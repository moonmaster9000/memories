module CouchRest
  module Model
    module Versioned
      class Base < CouchRest::Model::Base
        VERSION_REGEX = /(?:rev-)?(\d)+-[a-zA-Z0-9]+/

        before_update :add_version_attachment

        def add_version_attachment
          current_version = Attachment.new self.database.get(self.id, :rev => self.rev).to_json
          
          self.create_attachment( 
            :file => current_version, 
            :content_type => "application/json", 
            :name => "rev-#{self.rev}"
          )
        end
        
        def revert_to!(version=nil)
          version ||= previous_version
          if (match = version.to_s.match(VERSION_REGEX)) && match[1]
            version = match[1].to_i  
          end
          
          if properties = JSON.parse(read_attachment(version_id version))
            self.update_attributes(properties.delete_if {|k,v| ["_id", "_rev", "_attachments"].include? k})
          end
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
      end
    end
  end
end
