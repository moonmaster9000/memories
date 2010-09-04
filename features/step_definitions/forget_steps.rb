Given /^there is a book class with a notes property$/ do
  class BookWithNotes < CouchRest::Model::Base
    use_database VERSIONING_DB
    include Memories
    forget :notes

    property :title
    property :author
    property :notes
  end
end

When /^I create new versions of a book$/ do
  @book = BookWithNotes.create :title => 't1', :author => 'a1', :notes => 'n1' 
  @book.update_attributes :title => 't2', :author => 'a2', :notes => 'n2'
  @book.update_attributes :title => 't3', :author => 'a3', :notes => 'n3'
  @book.update_attributes :title => 't4', :author => 'a4', :notes => 'n4'
end

Then /^the notes should not be versioned$/ do
  @book.current_version.should == 4
  @book.notes.should == 'n4'
  (1..4).each do |n|
    @book.revert_to! n
    @book.title.should == "t#{n}" && @book.author.should == "a#{n}" && @book.notes.should == 'n4'
  end
end
