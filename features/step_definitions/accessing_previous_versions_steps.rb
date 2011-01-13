Given /^a document with versions$/ do
  @doc = Book.create :name => 'version 1'
  (2..10).each do |i|
    @doc.name = "version #{i}"
    @doc.save
  end
end

When /^I call the "versions" method$/ do 
  @versions = @doc.versions
end

Then /^I should get back an array proxy for previous versions$/ do
  @versions.should be_kind_of(Memories::VersionsProxy)
end

Given /^a "versions" array proxy for a document$/ do
  Given %{a document with versions}
  When %{I call the "versions" method}
end

When /^I call the \[\] method on the proxy with an integer that corresponds to an existing version$/ do
  @version = @versions[1]
end

Then /^I should get back a version proxy for that version of the document$/ do
  @version.class.should == Memories::VersionProxy
  @version.instance.name.should == "version 1"
end

When /^I call the \[\] method on the proxy with an integer that does not correspond to a version$/ do
  @version = @versions[25]
end

Then /^I should get back nil$/ do
  @version.should be_nil
end

When /^I call the \[\] method on the proxy with a range of valid versions$/ do
  @document_versions = @versions[1..8]
end

Then /^I should get back an array consisting of those valid versions$/ do
  @document_versions.count.should == 8
  @document_versions.each_with_index do |document, i|
    document.instance.name.should == "version #{i+1}"
    document.version_number.should == i+1
  end
end

When /^I call the \[\] method on the proxy with a range that includes versions that don't exist$/ do
  @document_versions = @versions[5..15]
end

Then /^I should get back an array containing the versions that existed$/ do
  @document_versions.count.should == 6
  @document_versions.each_with_index do |document, i|
    document.instance.name.should == "version #{i+5}"
    document.version_number.should == i+5
  end
end

When /^I call the \[\] method on the proxy with a range that does not include any valid versions$/ do
  @document_versions = @versions[15..50]
end

Then /^I should get back an empty array$/ do
  @document_versions.should == []
end

When /^I call the \[\] method on the proxy with a string corresponding to a valid version$/ do
  @version = @versions[@doc["_attachments"].keys.sort.first]
end

When /^I call the \[\] method on the proxy with a string that does not correspond to a valid version$/ do
  @version = @versions['jkfldsajklfdsa']
end

When /^I call the \#last method on the proxy$/ do
  @last = @versions.last
end

Then /^I should get a version proxy for the latest version of the document$/ do
  @last.class.should == Memories::VersionProxy
  @last.instance.name.should == @doc.name
end

When /^I update the document$/ do
  @doc.name = 'update!'
  @doc.save
end

When /^I call the \[\] method on the proxy with a range that includes the latest version$/ do
  @version_range = @versions[1..@doc.current_version]
end

Then /^I should recieve an array where the last element is the latest version$/ do
  @version_range.last.name.should == @doc.name
end

When /^I call the \#each method with a block$/ do
  @names = []
  @versions.compact.each {|v| @names << v.instance.name} 
end

Then /^I should be able to iterate through all versions of the document$/ do
  @names.each_with_index do |name, i|
    name.should == "version #{i+1}"
  end
end

When /^I access a version proxy within the \#versions array proxy$/ do
  @version_proxy = @versions[1]
end

When /^I call the \#version method on the proxy$/ do
  @version = @version_proxy.version
end

Then /^I should receive the revision number for that version$/ do
  @version.should == @doc.version_id(1) 
end

When /^I call the \#version_number method on the proxy$/ do
  @version_number = @version_proxy.version_number
end

Then /^I should receive the version number for that version$/ do
  @version_number.should == 1
end

Given /^a "versions" array proxy for a document with milestones$/ do 
  @doc = MainDoc.create :name => 'version 1' 
  @doc.name = 'version 2'
  @doc.milestone! do
    name "first milestone"
  end
  @doc.name = 'version 3'
  @doc.save
  @doc = MainDoc.get @doc.id
  @versions_proxy = @doc.versions
end

When /^I access a version proxy within the \#versions array proxy that happens to be a milestone$/ do
  @version_proxy = @versions_proxy[1] 
  @version_proxy.class.should == Memories::VersionProxy
end

When /^I call the \#milestone\? method on the proxy$/ do
  @is_milestone = @version_proxy.milestone?
end

Then /^I should receive true$/ do
  @is_milestone.should be_true
end

When /^I access a version proxy within the \#versions array proxy that is not a milestone$/ do
  @version_proxy = @versions_proxy[2]
end

Then /^I should receive false$/ do
  @is_milestone.should be_false
end

When /^I call the \#instance method on the proxy$/ do
  @instance = @version_proxy.instance
end

Then /^I should receive the instance corresponding to that version of the document$/ do
  @instance.name.should == "version 1"
end
