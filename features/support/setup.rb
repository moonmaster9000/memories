require 'spec/expectations'
$LOAD_PATH.unshift './lib'
require 'memories'

COUCHDB_SERVER = CouchRest.new "http://admin:password@localhost:5984"
VERSIONING_DB = COUCHDB_SERVER.database!('memories_test')

class MainDoc < CouchRest::Model::Base
  include Memories
  use_database VERSIONING_DB
  
  property :name
  view_by :name
end

class Book < MainDoc
end

Before do |scenario|
  VERSIONING_DB.delete!
  VERSIONING_DB.create!
end
