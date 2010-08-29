Given /^I have a document$/ do
  @book = Book.create :name => 'milestone test'
end

When /^I mark that document as a milestone$/ do
  @milestone_version = @book.rev
  @book.milestone!
end

Then /^that revision should show up as the newest milestone$/ do
  @book.latest_milestone.version.should == @milestone_version
end

When /^I mark that document as a milestone with an annotation$/ do
  @book.milestone! do
    name "First Milestone!"
    notes "This milestone is the first milestone ever created!"
  end
end

Then /^I should be able to retrieve that annotation from the milestone properties$/ do
  @book.latest_milestone.annotations.name.should == "First Milestone!"
  @book.latest_milestone.annotations.notes.should == "This milestone is the first milestone ever created!"
end

Given /^I have a document with (\d+) milestones$/ do |num_milestones|
  num_milestones = num_milestones.to_i
  @book = Book.new
  (0..((num_milestones - 1)*2)).step(2) do |i|
    @book.name = "book name #{i}"
    @book.save
    @book.name = "book name #{i+1}"
    @book.save
    @book.milestone!
  end
  @book.milestones.count.should == 5
end

When /^I revert the document to milestone (\d+)$/ do |milestone_number|
  @book.revert_to_milestone! milestone_number.to_i
end

Then /^the document should contain the properties of milestone (\d+)$/ do |milestone_number|
  @book.name.should == "book name #{(milestone_number.to_i * 2) - 1}"
end
