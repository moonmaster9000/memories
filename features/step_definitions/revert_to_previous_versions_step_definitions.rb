Given %r{^I have 5 versions of a document$} do
  @book = Book.create :name => "version 1"
  (2..5).each {|i| @book.name = "version #{i}"; @book.save}
end

Transform %r{version +\d+} do |version|
  version.gsub('version ', '').to_i
end

When %r{^I revert the document to (version +\d+)$} do |version|
  @book.revert_to! version
end

When %r{^I soft revert the document to (version +\d+)$} do |version|
  @version_before_soft_revert = @book.rev
  @book.revert_to version
end

Then /the unsaved document should contain the properties of (version +\d+)/ do |version|
  @book.name.should == "version #{version}"
  @book.rev.should == @version_before_soft_revert
end

Then /the document should contain the properties of (version +\d+)/ do |version|
  @book.name.should == "version #{version}"
end
