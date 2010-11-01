When /^I create a class that calls the remember_attachments! method$/ do
  class StaticPage < CouchRest::Model::Base
    use_database VERSIONING_DB
    include Memories

    remember_attachments!

    property :html
  end
end

Then /^all attachments should be versioned by Memories$/ do
  home_page = StaticPage.new :html => "<h1> Home Page! </h1>"
  home_page.create_attachment :name => "screen.css", :content_type => 'text/css', :file => Memories::Attachment.new("h1 { font-size: 10px }")
  home_page.save

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/screen.css"
  css.body.should == "h1 { font-size: 10px }"

  home_page.update_attachment :name => "screen.css", :content_type => 'text/css', :file => Memories::Attachment.new("h1 { font-size: 20px }")
  home_page.save

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/screen.css"
  css.body.should == "h1 { font-size: 20px }"

  home_page.revert_to! 1

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/screen.css"
  css.body.should == "h1 { font-size: 10px }"
end

When /^I create a class that calls the remember_attachments! method with strings and regexes$/ do
  class HtmlPage < CouchRest::Model::Base
    use_database VERSIONING_DB
    include Memories

    remember_attachments! %r{^static/.*\.js$}, "README.txt"

    property :html
  end
end

Then /^all attachments with names matching any of those strings and regexes should be versioned by Memories$/ do
  home_page = HtmlPage.new :html => "<h1> Home Page! </h1>"
  home_page.create_attachment :name => "static/screen.css", :content_type => 'text/css',        :file => Memories::Attachment.new("h1 { font-size: 10px }")
  home_page.create_attachment :name => "static/stuff.js",   :content_type => 'application/js',  :file => Memories::Attachment.new("var v1 = 'test';")
  home_page.create_attachment :name => "README.txt",        :content_type => 'text/plain',      :file => Memories::Attachment.new("this is the README")
  home_page.save

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/screen.css"
  css.body.should == "h1 { font-size: 10px }"
  js = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/stuff.js"
  js.body.should == "var v1 = 'test';"
  readme = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/README.txt"
  readme.body.should == "this is the README"

  home_page.update_attachment :name => "static/screen.css",      :content_type => 'text/css',        :file => Memories::Attachment.new("h1 { font-size: 20px }")
  home_page.update_attachment :name => "static/stuff.js", :content_type => 'application/js',  :file => Memories::Attachment.new("var v1 = 'testing';")
  home_page.update_attachment :name => "README.txt",      :content_type => 'text/plain',      :file => Memories::Attachment.new("this is the README!")
  home_page.save

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/screen.css"
  css.body.should == "h1 { font-size: 20px }"
  js = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/stuff.js"
  js.body.should == "var v1 = 'testing';"
  readme = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/README.txt"
  readme.body.should == "this is the README!"


  home_page.revert_to! 1

  css = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/screen.css"
  css.body.should == "h1 { font-size: 20px }"
  js = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/static/stuff.js"
  js.body.should == "var v1 = 'test';"
  readme = RestClient.get "http://admin:password@localhost:5984/memories_test/#{home_page.id}/README.txt"
  readme.body.should == "this is the README"


end


Given /^a document that versions attachments$/ do
  class SomeDoc < CouchRest::Model::Base
    use_database VERSIONING_DB
    include Memories

    remember_attachments!
  end
end

Given /^the first version of the document has no attachments$/ do
  @doc = SomeDoc.create
end

Given /^the next version of the document has "([^"]*)" attachments?$/ do |num_attachments|
  0.upto(num_attachments.to_i) do |i|
    props = {:name => "attachment_#{i}", :content_type => "text/plain", :file => ::Memories::Attachment.new("this is attachment #{i}")}
    @doc.has_attachment?(props[:name]) ? @doc.update_attachment(props) : @doc.create_attachment(props)
    @doc.save
  end
end

When /^I revert the document to the first version$/ do
  @doc.revert_to! 1
end

Then /^the document should have no attachments$/ do
  (@doc["_attachments"] || {}).keys.select {|a| !a.match(::Memories::VERSION_REGEX)}.count.should == 0
end

When /^I revert the document to the second version$/ do
  @doc.revert_to! 2
end

When /^I revert the document to the third version$/ do
  @doc.revert_to! 3
end

Then /^the document should have "([^"]*)" attachments?$/ do |num_attachments|
  (@doc["_attachments"] || {}).keys.select {|a| !a.match(::Memories::VERSION_REGEX)}.count.should == num_attachments.to_i
end
