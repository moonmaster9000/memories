When /^I soft revert that document to a previous version$/ do
  @doc = @doc.revert_to 1
end

When /^I call \#logical_revision$/ do
  @logical_revision = @doc.logical_revision
end

Then /^I should receive the revision of that previous version$/ do
  @logical_revision.should == @doc.versions[1].revision
end

When /^I call \#logical_version_number$/ do
  @logical_version_number = @doc.logical_version_number
end

Then /^I should receive the version number of that previous version$/ do
  @logical_version_number.should == @doc.versions[1].version_number
end

Then /^the logical revision should equal the actual revision$/ do
  @doc.logical_revision.should == "rev-" + @doc.rev
end

Then /^the logical version number should equal the actual version number$/ do
  @doc.logical_version_number.should == @doc.version_number(@doc.rev)
end
