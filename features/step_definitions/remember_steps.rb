When /^I create a class that uses the \#remember method$/ do
  class SelectiveMemory < CouchRest::Model::Base
    use_database VERSIONING_DB
    include Memories
    remember :prop1, :prop2

    property :prop1
    property :prop2
    property :prop3
    property :prop4
  end

end

Then /^only the properties specified in \#remember should be versioned$/ do
  s = SelectiveMemory.create :prop1 => "prop1 1", :prop2 => "prop2 1", :prop3 => "prop3 1", :prop4 => "prop4 1"
  (2..5).each do |i|
    s.prop1 = "prop1 #{i}"
    s.prop2 = "prop2 #{i}"
    s.prop3 = "prop3 #{i}"
    s.prop4 = "prop4 #{i}"
    s.save
  end
  s.prop1.should == "prop1 5"
  s.prop2.should == "prop2 5"
  s.prop3.should == "prop3 5"
  s.prop4.should == "prop4 5"
 
  (1..5).each do |i|
    s.revert_to! i
    s.prop1.should == "prop1 #{i}"
    s.prop2.should == "prop2 #{i}"
    s.prop3.should == "prop3 5"
    s.prop4.should == "prop4 5"
  end
end

When /^I create a class that tries to use both \#remember and \#forget$/ do
end

Then /^the Memories library should throw an exception\.$/ do
  proc {class SoConfused < CouchRest::Model::Base
    include Memories

    forget :prop1
    remember :prop1
  end
  }.should raise_error(StandardError, "Ambiguous use of both #remember and #forget.")
end
