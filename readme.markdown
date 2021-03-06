#Introduction

A simple gem for adding versioning to your CouchRest::Model::Base documents. When you update a document, the previous version gets 
stored as an attachment on the document. This versioning strategy was originally created here: http://blog.couch.io/post/632718824/simple-document-versioning-with-couchdb

##Installation

    $ gem install memories

## Documentation

Browse the documentation on rubydoc.info: http://rubydoc.info/gems/memories/frames

##How does it work?

Just "include Memories" in your "CouchRest::Model::Base" classes and let the auto-versioning begin.

###Basic Versioning

Here's how basic versioning works. Every time you save your document, you get a new version. You have the ability to roll back to a previous version.

    class Book < CouchRest::Model::Base
      include Memories
      use_database SOME_DATABASE
      
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

If you'd like to exclude certain properties from versioning, use the #forget class method:

    class Book < CouchRest::Model::Base
      include Memories
      use_database SOME_DATABASE

      forget :notes
      
      property :name
      property :notes
      view_by :name
    end

    b = Book.create :name => "2001", :notes => "creating the book."
    b.current_version #==> 1
    b.name = "2001: A Space Odyssey"
    b.notes += "updating the title. might ship today. 9/2/2010. MKP"
    b.save
    b.current_version #==> 2
    b.previous_version #==> 1
    p b.name #==> "2001: A Space Odyssey"
    p b.notes # ==> "creating the book. updating the title. might ship today. 9/2/2010. MKP"
    b.revert_to! 1
    p b.name #==> "2001"
    p b.notes # ==> "creating the book. updating the title. might ship today. 9/2/2010. MKP"
    b.current_version #==> 3

If you'd like to explicitly define which properties to version, use the #remember method. It works just like #forget, but in reverse. Duh.

###Milestones

As of version 0.2.0, Memories also supports milestones. Milestones are special versions that you want to flag in some way.
For example, suppose you were creating a content management system, and every time someone publishes an article to the website, you want to flag the version
they published as a milestone. 

    class Article < CouchRest::Model::Base
      include Memories
      use_database SOME_DATABASE
      
      property :title
      property :author
      property :body

      def publish!
        # .... publishing logic
      end
    end

    a = Article.create(
      :title => "Memories gem makes versioning simple", 
      :author => "moonmaster9000", 
      :body => <<-ARTICLE
        Check it out at http://github.com/moonmaster9000/memories
      ARTICLE
    )
    a.save
    a.publish!
    a.current_version #==> 1 
    a.milestone! do
      name "First publish."
      notes "Passed all relevant editing. Signed off by moonmaster10000"
    end

Notice that we annotated our milestone; we gave it a name, and some notes. You can annotate with whatever properties you desire. The annotation do block is entirely optional.
Now that we've created a milestone, let's inspect it via the `milestones` array: 

    a.milestones.count #==> 1
    a.milestones.last.version # ==> 'rev-1-893428ifldlfds9832'
    a.milestones.last.version_number # ==> 1
    a.milestones.last.annotations.name # ==> "First publish."
    a.milestones.last.annotations.notes # ==> "Passed all relevant editing. Signed off by moonmaster 10000"
    a.milestones.last.instance.title # ==> Memories gem makes versioning simple

Now, let's imagine that we've made some more edits / saves to the document, but they don't get approved. Now we want to revert to the version the document was
at at the first milestone. How do we do that? Simple!

    a.revert_to_milestone! 1

And now our document properties are back to the where they were when we first published the document.

If you want to access the version instance of a milestone, simply use the "instance" method: 
    
    a.milestones.first.instance.title #==> returns the "title" attribute on the first milestone
    a.milestones.each do |m|
      puts "Version: " + m.version
      puts "Title: " + m.instance.title
    end

## Attachments

By default, memories doesn't version attachments. If you'd like to version attachments, simply call the `remember_attachments!` class method in your 
class definition: 

    class MyDoc < CouchRest::Model::Base
      use_database MY_DB
      include Memories

      remember_attachments!
    end

If you only want specific attachments versioned, pass 
strings and/or regular expressions to this macro. Any attachments
with matching names will be versioned.

    class HtmlPage < CouchRest::Model::Base
      use_database MY_DB
      include Memories

      remember_attachments! "image.png", %r{stylesheets/.*}
    end

## Accessing Previous Versions

You can access old versions of your document via the "versions" method; it will return a proxy with array-like and hash-like access to previous versions.

    @doc.versions[1].instance # ==> returns version 1 of your document
    @doc.versions[1].revision # ==> 'rev-1-jkfldsi32849032894032'
    @doc.versions[1].version_number # ==> 1
    @doc.versions['rev-1-kjfdsla3289430289432'].instance # ==> returns version 1 of your document
    @doc.versions[1..7] # ==> returns version proxies 1 through 7 of your document
    @doc.versions.count # ==> returns the number of versions of your document
    @doc.versions.last # ==> returns a proxy for the latest version of your document
    @doc.versions.first # ==> returns a proxy for the first version of your document
    @doc.versions.each do |v|
      puts v.instance.some_property
    end

## Logical Revision Numbers

As of version 0.3.1, when you soft revert a document (#revert_to), you can access the logical revision and logical version numbers of that document. 

For example, suppose you soft revert a document with 10 versions to version 2. 
    
    @doc.current_version # ==> 10 
    @doc.revert_to 2

When you ask the logical revision, you'll receive the revision number of version 2:
    
    @doc.logical_revision #==> 'rev-2-kfdlsa432890432890432'

Similarly, the logical version number:

    @doc.logical_version_number #==> 2

However, as soon as you save the document, the logical revision and logical version number will simply mirror those of the actual document
    
    @doc.save
    @doc.rev #==> '11-qwerty1234567890'
    @doc.logical_revision #==> 'rev-11-qwerty1234567890'
    @doc.logical_version_number #==> 11

