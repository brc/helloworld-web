#!/usr/bin/env ruby

require 'sinatra'

# (`set' is part of the sinatra DSL)
set :bind, '0.0.0.0'
set :port, ENV['PORT'] || '8080'

get '/' do
  'Hello, World!'
end
