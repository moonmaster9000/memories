Given /^a document model that remembers attachments with the word "([^"]*)" in the name$/ do |arg1|
  class DocWithAttachments < MainDoc
    remember_attachments! /attachment/
  end
end

Given /^a document that has attachments "([^"]*)", "([^"]*)", "([^"]*)"$/ do |attach1, attach2, attach3|
  @doc = DocWithAttachments.new
  [attach1, attach2, attach3].each { |a|
    @doc.create_attachment :name => a, :content_type => "text/plain", :file => ::Memories::Attachment.new(a)
  }
  @doc.save
end

When /^I call the \#attachments_to_remember method$/ do
  @attachments = @doc.attachments_to_remember
end

Then /^"([^"]*)" should be in the list$/ do |attachment|
  @attachments.include?(attachment).should be_true
end

Then /^"([^"]*)" should not be in the list$/ do |attachment|
  @attachments.include?(attachment).should be_false
end

When /^I call the \#attachments_to_forget method$/ do
  @attachments = @doc.attachments_to_forget
end
