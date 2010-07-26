require 'spec/expectations'
$LOAD_PATH.unshift './lib'
require 'memories'


COUCHDB_SERVER = CouchRest.new "http://localhost:5984"
VERSIONING_DB = COUCHDB_SERVER.database!('memories_test')

class Book < CouchRest::Model::Versioned::Base
  use_database VERSIONING_DB
  
  property :name
  view_by :name
end

After do |scenario|
  VERSIONING_DB.delete!
  VERSIONING_DB.create!
end
