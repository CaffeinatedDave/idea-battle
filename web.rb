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
  Ideas.where("seen > 0").order("chosen/seen desc, chosen desc, seen asc").to_json
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
  body = request.body.read
  begin
    query = JSON.parse(body, symbolize_keys: true)
  rescue
    # Ok so it's not json... hope it's real args..
    query = {"uuid" => request["uuid"], "vote" => request["vote"].to_i}
  end
  logger.info query.to_s

  uuid = query["uuid"]

  logger.info("Looking for uuid: " + uuid.to_s)
  # find question asked
  question = $votes[uuid]
  vote = query["vote"]

  # register vote if valid
  if question != nil && (vote == question[:left] || vote == question[:right])
    $votes.delete(uuid)
    logger.info("Voting for " + vote.to_s + " given the option of " + question[:left].to_s + " or " + question[:right].to_s)

    left = Ideas.find(question[:left])
    right = Ideas.find(question[:right])

    if left[:id] == vote
      Ideas.update(left[:id], {:seen => left[:seen] + 1, :chosen => left[:chosen] + 1})
      Ideas.update(right[:id], {:seen => right[:seen] + 1})
    else 
      Ideas.update(left[:id], {:seen => left[:seen] + 1})
      Ideas.update(right[:id], {:seen => right[:seen] + 1, :chosen => right[:chosen] + 1})
    end
    {:status => "OK"}.to_json
  else
    if question == nil
      status 404
      {:status => "NOT FOUND"}.to_json
    else
      status 400
      {:status => "BAD REQUEST"}.to_json
    end 
  end
  
  # return OK regardless
end

options '/game/vote/?' do
  response.headers['Access-Control-Allow-Methods'] = 'POST'
  ""
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
    ActiveRecord::Base.connection.close
    sleep 3600
  end
end
