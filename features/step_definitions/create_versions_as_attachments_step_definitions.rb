When %r{I create a new document} do
  @book = Book.create :name => 'test'
end

Then %r{that document should not have any versions} do
  @book.current_version.should == 1
end

When %r{I update that document} do
  @book.name = 'test 2'
  @book.save
end

Then %r{the properties of the previous version should be saved as an attachment} do
  properties = JSON.parse @book["_attachments"][@book.version_id @book.previous_version]["data"]
  properties["name"].should == "test"
  @book.name.should == "test 2"
end
