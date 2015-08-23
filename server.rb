require 'uri'
require 'logger'
require 'redis'

REDIS_KEY = "state"

# Pusher.logger = Logger.new(STDOUT)
$redis = Redis.connect(url: ENV.fetch("REDIS_URL", ENV.fetch("REDISTOGO_URL", "redis://localhost:6379/0")))

$fire_state = $redis.get(REDIS_KEY) || "010"
$redis.set(REDIS_KEY, $fire_state)

# PUSHER_URL = ENV['PUSHER_URL'] || 'http://8d1a554cc7664a43eed1:0c00881f89481c483193@api.pusherapp.com/apps/33682'
# pusher_url = URI.parse PUSHER_URL
# PUSHER_KEY = pusher_url.user
# PUSHER_SECRET = pusher_url.password
# PUSHER_APP_ID = pusher_url.path.split('/').last

# $pusher_client = Pusher::Client.new({
#   app_id: PUSHER_APP_ID,
#   key: PUSHER_KEY,
#   secret: PUSHER_SECRET
# })


class Server < Sinatra::Base

  get "/" do
    "Traffic light, ready for command !"
  end

  get "/state" do
  	$fire_state
  end

  post "/state" do
    ap params
    red =    parse_param_state params['red']
    orange = parse_param_state params['orange']
    green =  parse_param_state params['green']

    state = {red: red, orange: orange, green: green}

    state = [
      red == 'on' ? 'y': 'n',
      orange == 'on' ? 'y': 'n',
      green == 'on' ? 'y': 'n'
    ].join('')
    ap state
    result = nil #send_pusher_instruction 'state', state
    "State updated ! (#{result.inspect})"
  end

  post "/instructions" do
    puts params.inspect
    instruction = params['instruction']
    result = nil #send_pusher_instruction instruction
    "Instruction #{instruction.inspect} sent to Pusher with result #{result.inspect}"
  end

  post "/pusher_hooks" do
    puts params.inspect
    "OK !"
  end

  def parse_param_state(param)
    case param
    when 'on' then 'on'
    when 'off' then 'off'
    when 'blinking' then 'blinking'
    else 'off'
    end
  end
end

CI_URL = ENV['CI_URL'] || "http://mathieu:pyroti@ci.preplaysports.com/go/cctray.xml"
CI_USERNAME = ENV['CI_USERNAME'] || 'mathieu'
CI_PASSWORD = ENV['CI_PASSWORD']
CI_PROJECT  = ENV['CI_PROJECT']  || "PPS :: tests :: tests"

def send_pusher_instruction(instruction, data=nil)
  p nil # $pusher_client.trigger(['instructions'], instruction, data || {})
end

def send_lights_state(red, orange, green)
  state = [red, orange, green].map { |s| s == "on" || s == true ? 'y' : 'n' }.join("")

  return if $fire_state == state

  puts "Sending state #{state}"
  send_pusher_instruction('state', state)
  $fire_state = state
  $redis.set(REDIS_KEY, $fire_state)
  puts "Done."
end

def check_ci
  puts "Getting CI status..."
  res = HTTParty.get(CI_URL, :basic_auth => {:username => CI_USERNAME, :password => CI_PASSWORD})
  # puts res
  xml = MultiXml.parse res
  # ap xml

  project = (xml && xml['Projects'] && xml['Projects']['Project'] || []).detect { |p| p['name'] == CI_PROJECT }
  ap project

  activity = project['activity']
  last_status = project['lastBuildStatus']
  ap [activity, last_status]

  orange = activity != "Sleeping"
  red = last_status != 'Success'
  green = last_status == 'Success'
  ap [red, orange, green]

  send_lights_state(red, orange, green)
end

STATES = %w(on off) #blinking

# Thread.new do
#   puts "CI polling / Pusher thread created."
#
#   loop do
#     begin
#       # instruction = %w(red_on orange_on green_on red_off orange_off green_off).sample
#       # puts "Sending instruction #{instruction.inspect} to Pusher..."
#       # send_pusher_instruction instruction
#
#       # send_lights_state(STATES.sample, STATES.sample, STATES.sample)
#
#       check_ci
#       sleep(2)
#     rescue => e
#       ap e
#       ap e.backtrace
#     end
#   end
#
# end