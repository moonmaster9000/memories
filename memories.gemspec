Gem::Specification.new do |s|
  s.name        = "memories"
  s.summary     = "Versioning for your couchrest_model documents."
  s.version     = File.read "VERSION"
  s.authors     = ["Matt Parker", "Gary Cheong"]
  s.email       = "moonmaster9000@gmail.com"
  s.description = "CouchDB has built in document versioning, but you can't rely on it for version control. This is an implementation of a version-as-attachments approach created by @jchris."
  s.files       = Dir["lib/**/*"] << "VERSION" << "readme.markdown"
  s.homepage    = "http://github.com/moonmaster9000/memories"

  s.add_dependency              'couchrest_model', '~> 1.0.0'
  s.add_development_dependency  'cucumber'
  s.add_development_dependency  'rspec'
end
