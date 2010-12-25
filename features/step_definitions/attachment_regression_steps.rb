Given /^a document with no attachments$/ do
  @doc = Book.create :name => "test"
end

When /^I add an attachment "([^"]*)"$/ do |attachment_name|
  @doc.create_attachment :name => attachment_name, :content_type => "text/plain", :file => Memories::Attachment.new("data for #{attachment_name}")
end

When /^I save$/ do
  @doc.save
end

When /^I revert to version "([^"]*)"$/ do |version|
  @doc.revert_to! version.to_i
end

Then /^I should be able to access "([^"]*)"$/ do |attachment_name|
  @doc["_attachments"][attachment_name].should_not be_nil
  @doc["_attachments"][attachment_name]["data"].should == "data for #{attachment_name}"
end
