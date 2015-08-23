require 'uri'
require 'logger'
require 'redis'

$redis = Redis.connect(url: ENV.fetch("REDIS_URL", ENV.fetch("REDISTOGO_URL", "redis://localhost:6379/0")))

class FireState
  REDIS_KEY = "fire_state"

  DEFAULT_STATE = '101'

  def get
    return random if ENV['PARTY_MODE']
    $redis.get(REDIS_KEY) || DEFAULT_STATE
  end

  def random
    3.times.map { %w(1 0).sample }.join('')
  end

  def set(red: false, orange: false, green: false)
    state = [
      red     ? '1': '0',
      orange  ? '1': '0',
      green   ? '1': '0'
    ].join('')
    p set: state
    $redis.set(REDIS_KEY, state)
  end

  def red!
    set(red: true)
  end

  def orange!
    set(orange: true)
  end

  def green!
    set(green: true)
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
    FireState.new.set(red: red, orange: orange, green: green)
  end

  def parse_param_state(param)
    case param
    when 'on' then true
    when '1' then true
    when 'true' then true
    else false
    end
  end
end

CI_REQ_HEADERS = {"Accept".freeze => "application/json".freeze}
CI_TOKEN = ENV.fetch('CIRCLE_CI_AUTH_TOKEN')
PROJECT = ENV.fetch('CIRCLE_CI_PROJECT')
CI_URL="https://circleci.com/api/v1/project/#{PROJECT}?circle-token#{CI_TOKEN}=&limit=1"

FAILURE_OUTCOMES = %w(
  canceled
  infrastructure_fail
  timedout
  failed
)

SUCCESS_OUTCOMES = %w(
  no_tests
  success
)

def check_ci
  puts "Getting CI status..."
  puts CI_URL
  response = HTTParty.get(CI_URL, headers: CI_REQ_HEADERS.dup)
  # puts res
  builds = JSON.parse(response.body)
  p builds
  last_build = builds[0]

  #:canceled, :infrastructure_fail, :timedout, :failed, :no_tests or :success
  outcome = last_build.fetch('outcome')

  # :retried, :canceled, :infrastructure_fail, :timedout, :not_run, :running, :failed, :queued, :scheduled, :not_running, :no_tests, :fixed, :success
  status = last_build.fetch('status')

  p outcome: outcome  #'success', 'running', 'fail

  case
  when status == "running" then FireState.new.orange!
  when FAILURE_OUTCOMES.include?(outcome) then Firestate.new.red!
  when SUCCESS_OUTCOMES.include?(outcome) then Firestate.new.green!
  else Firestate.new.set(red: true, green: true)
  end
end

Thread.abort_on_exception = true

Thread.new do
  loop do
    check_ci
    sleep(1)
  end

end