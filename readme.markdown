#Introduction

A simple gem for adding versioning to your CouchRest::Model::Base documents. When you update a document, the previous version gets 
stored as an attachment on the document. This versioning strategy was originally created here: http://blog.couch.io/post/632718824/simple-document-versioning-with-couchdb

##Installation

    $ gem install memories

##How does it work?

Just "include Memories" in your "CouchRest::Model::Base" documents and let the auto-versioning begin.

    class Book < CouchRest::Model::Base
      include Memories
      use_database VERSIONING_DB
      
      property :name
      view_by :name
    end

    b = Book.create :name => "2001"
    b.current_version #==> 1
    b.name = "2001: A Space Odyssey"
    b.save
    b.current_version #==> 2
    b.previous_version #==> 1
    b.name #==> "2001: A Space Odyssey"
    b.revert_to! 1
    b.name #==> "2001"
    b.current_version #==> 3
