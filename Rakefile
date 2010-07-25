require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = "memories"
    gemspec.summary     = "Versioning for your couchrest_model documents."
    gemspec.description = "CouchDB has built in document versioning, but you can't rely on it for version control. " +
                          "This is an implementation of a version-as-attachments approach suggested by @jchris." + 
    gemspec.email       = "moonmaster9000@gmail.com"
    gemspec.files       = FileList['lib/**/*.rb', 'README.rdoc']
    gemspec.homepage    = "http://github.com/moonmaster9000/memories"
    gemspec.authors     = ["Matt Parker"]
    gemspec.add_dependency('couchrest_model', '>= 1.0.0.beta7')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
