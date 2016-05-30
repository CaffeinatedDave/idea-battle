require 'dotenv'
require 'erb'
require 'erubis'
require 'json'
require 'open-uri'
require 'securerandom'
require 'sinatra'
require 'sinatra/activerecord'

require './models/ideas'

Dotenv.load

use Rack::Logger
set :show_exceptions, :after_handler

configure :production, :development do
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
  if ENV['debug'] == true
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
  mockIdeaLeft = {:title => "I'm a left idea", :description => "I have no idea what I'm doing...."}
  mockIdeaRight = {:title => "I'm a rightt idea", :description => "I have no idea what I'm doing either...."}

  # generate uuid
  uuid = SecureRandom.uuid

  # save question to DB
  
  # return question to caller
  {
    :uuid => uuid,
    :left => mockIdeaLeft,
    :right => mockIdeaRight
  }.to_json
end 

post '/game/vote/?' do
  # find question asked
  # register vote if valid

  # return OK regardless
  {:status => "OK"}.to_json
end

after do
  # Close the connection after the request is done so that we don't
  # deplete the ActiveRecord connection pool.
  ActiveRecord::Base.connection.close
end
