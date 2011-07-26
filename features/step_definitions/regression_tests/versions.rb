Given /^an unsaved instance of a document that includes Memories$/ do
  @instance = MainDoc.new
end

When /^I call the "([^"]*)" on that instance$/ do |code|
  @result = eval "@instance.#{code}"
end

Then /^I should get (\d+)$/ do |result|
  @result.should == result.to_i
end
