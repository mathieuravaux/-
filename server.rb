require 'uri'
require 'logger'

Pusher.logger = Logger.new(STDOUT)


PUSHER_URL = ENV['PUSHER_URL'] || 'http://8d1a554cc7664a43eed1:0c00881f89481c483193@api.pusherapp.com/apps/33682'
pusher_url = URI.parse PUSHER_URL
PUSHER_KEY = pusher_url.user
PUSHER_SECRET = pusher_url.password
PUSHER_APP_ID = pusher_url.path.split('/').last

pusher_client = Pusher::Client.new({
  app_id: PUSHER_APP_ID,
  key: PUSHER_KEY,
  secret: PUSHER_SECRET
})


class Server < Sinatra::Base

  get "/" do
    "Traffic light, ready for command !"
  end

  post "/status" do
    "At your orders !"
  end

  post "/instructions" do
    puts params.inspect
    instruction = params[:instruction] || params['instruction']
    result = send_pusher_instruction instruction
    "Instruction #{instruction.inspect} sent to Pusher with result #{result.inspect}"
  end
  
  post "/pusher_hooks" do
    puts params.inspect
    "OK !"
  end
end

CI_URL = ENV['CI_URL'] || "http://mathieu:pyroti@ci.preplaysports.com/go/cctray.xml"
CI_USERNAME = ENV['CI_USERNAME'] || 'mathieu'
CI_PASSWORD = ENV['CI_PASSWORD']
CI_PROJECT  = ENV['CI_PROJECT']  || "PPS :: tests :: tests"

def send_pusher_instruction(instruction, data=nil)
  ap pusher_client.trigger(['instructions'], instruction, data || {})
end

def check_ci
  puts "Getting CI status..."
  res = HTTParty.get(CI_URL, :basic_auth => {:username => CI_USERNAME, :password => CI_PASSWORD})
  puts res
  xml = MultiXml.parse res
  ap xml
  
  project = (xml && xml['Projects'] && xml['Projects']['Project'] || []).detect { |p| p['name'] == CI_PROJECT }
  ap project
  
  activity = project['activity']
  last_status = project['lastBuildStatus']
  
  orange = activity != "Sleeping"
  red = last_status != 'Success'
  green = last_status == 'Success'
  
  send_pusher_instruction(state, {red: red, orange: orange, green: green})
end

Thread.new do
  puts "CI polling / Pusher thread created."
  
  loop do
    # instruction = %w(red_on orange_on green_on red_off orange_off green_off).sample
    # puts "Sending instruction #{instruction.inspect} to Pusher..."
    # send_pusher_instruction instruction
    # check_ci
    sleep(5)
  end
  
  
end