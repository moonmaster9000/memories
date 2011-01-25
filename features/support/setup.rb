require 'rspec/expectations'
$LOAD_PATH.unshift './lib'
require 'memories'

COUCHDB_SERVER = CouchRest.new "http://admin:password@localhost:5984"
VERSIONING_DB = COUCHDB_SERVER.database!('memories_test')

class MainDoc < CouchRest::Model::Base
  include Memories
  use_database VERSIONING_DB
  remember_attachments! 

  property :name
  view_by :name
end

class Book < MainDoc
  remember_attachments!
end

class BookWithTimestamp < Book
  timestamps!
  before_save :update_timestamp
    
  def overwrite_timestamp_with(time)
    @with_timestamp = time
  end
  
private
  def update_timestamp
    write_attribute('updated_at', @with_timestamp)  if @with_timestamp
  end
end

Before do |scenario|
  VERSIONING_DB.delete!
  VERSIONING_DB.create!
end
