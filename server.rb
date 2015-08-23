require 'uri'
require 'logger'
require 'redis'

$redis = Redis.connect(url: ENV.fetch("REDIS_URL", ENV.fetch("REDISTOGO_URL", "redis://localhost:6379/0")))

class FireState
  REDIS_KEY = "fire_state"

  DEFAULT_STATE = '101'

  def get
    $redis.get(REDIS_KEY) || DEFAULT_STATE
  end

  def set(red, orange, green)
    state = [
      red     ? '1': '0',
      orange  ? '1': '0',
      green   ? '1': '0'
    ].join('')
    p set: state
    $redis.set(REDIS_KEY, state)
  end

  def set_colors(red, orange, green)
  end

end

class Server < Sinatra::Base

  get "/" do
    "Traffic light, ready for command !"
  end

  get "/state" do
  	FireState.new.get
  end

  post "/state" do
    p params
    red =    parse_param_state params['red']
    orange = parse_param_state params['orange']
    green =  parse_param_state params['green']
    FireState.new.set(red, orange, green)
  end

  def parse_param_state(param)
    case param
    when 'on' then true
    else false
    end
  end
end

CI_URL = ENV['CI_URL'] || "http://mathieu:pyroti@ci.preplaysports.com/go/cctray.xml"
CI_USERNAME = ENV['CI_USERNAME'] || 'mathieu'
CI_PASSWORD = ENV['CI_PASSWORD']
CI_PROJECT  = ENV['CI_PROJECT']  || "PPS :: tests :: tests"

def check_ci
  puts "Getting CI status..."
  res = HTTParty.get(CI_URL, :basic_auth => {:username => CI_USERNAME, :password => CI_PASSWORD})
  # puts res
  xml = MultiXml.parse res
  # p xml

  project = (xml && xml['Projects'] && xml['Projects']['Project'] || []).detect { |p| p['name'] == CI_PROJECT }
  p project

  activity = project['activity']
  last_status = project['lastBuildStatus']
  p [activity, last_status]

  orange = activity != "Sleeping"
  red = last_status != 'Success'
  green = last_status == 'Success'
  p [red, orange, green]

  FireState.new.set(red, orange, green)
end

STATES = %w(on off) #blinking

# Thread.new do
#   puts "CI polling thread created."
#
#   loop do
#     begin
#       check_ci
#       sleep(2)
#     rescue => e
#       p e
#       p e.backtrace
#     end
#   end
#
# end