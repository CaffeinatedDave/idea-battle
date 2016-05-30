require 'dotenv'
require 'erb'
require 'erubis'
require 'json'
require 'open-uri'
require 'securerandom'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cross_origin'

require './models/ideas'

Dotenv.load

use Rack::Logger
set :show_exceptions, :after_handler

set :server, 'thin'
set :bind, '0.0.0.0'

configure :production, :development do
  enable :cross_origin
  db = URI.parse(ENV['DATABASE_URL'])

  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

$votes = {}
$ids = []

helpers do
  def logger
    request.logger
  end
end

not_found do
  status 404
  '{error: "not found"}'
end

before do
  if ENV['debug']
    logger.info request.env.to_s
  end
end

get "/list/?" do
  # Get all ideas, sorted by vote %s???
  # v2. Funk it.
end

get '/' do
  # trivially just load a single page
  erb :index
end

get '/game/?' do  
  # find two ideas
  leftId = $ids.sample
  rightId = $ids.sample
 
  leftIdea = Ideas.find(leftId) 
  rightIdea = Ideas.find(rightId) 

  # generate uuid
  uuid = SecureRandom.uuid

  # save question to internal hash
  $votes[uuid] = {:left => leftId, :right => rightId, :expires => (Time.now + 300).to_i}
  
  # return question to caller
  response = {
    :uuid => uuid,
    :left => leftIdea,
    :right => rightIdea
  }
  
  response.to_json
end 

post '/game/vote/?' do
  query = JSON.parse(request.body.read, symbolize_keys: true)
  logger.info query.to_s

  uuid = query["uuid"]

  logger.info("Looking for uuid: " + uuid.to_s)
  # find question asked
  question = $votes[uuid]
  # register vote if valid
  if question != nil 
    logger.info("Voting for " + query["vote"].to_s + " given the option of " + question[:left].to_s + " or " + question[:right].to_s)
    $votes.delete(uuid)
  end
  
  # return OK regardless
  {:status => "OK"}.to_json
end

after do
  # Close the connection after the request is done so that we don't
  # deplete the ActiveRecord connection pool.
  ActiveRecord::Base.connection.close
end


Thread.new do 
  while true do
    $votes = $votes.select { |_,v| (v[:expires] >= Time.now.to_i) }
    warn "Votes buffer contains " + $votes.size.to_s + " entries"
    sleep 30
  end
end

Thread.new do 
  while true do
    $ids = Ideas.all.map(&:id)
    warn "Got " + $ids.size.to_s + " ideas"
    sleep 3600
  end
end
