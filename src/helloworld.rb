#!/usr/bin/env ruby

# Imports from Gemfile bundle
require "google/cloud/datastore"
require 'sinatra'

# Instantiate Firestore client
datastore = Google::Cloud::Datastore.new

# Define helper method to query datastore
def query_db(connector, kind, key)
  begin
    key_id = connector.key(kind, key)
    connector.find(key_id)
  rescue => e
    $stderr.puts "error querying database: #{e}"
  end
end

# Configure web server
# (`set' is part of the sinatra DSL)
set :bind, '0.0.0.0'
set :port, ENV['PORT'] || '8080'

# Define routes
get '/' do
  if entity = query_db(datastore, 'comm', 'poc-demo')
    entity.properties['msg']
  else
    #  return an error
    halt 503, 'Database query failed'
  end
end
