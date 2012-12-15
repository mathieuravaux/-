class Server < Sinatra::Base

  get "/" do
    "Traffic light, ready for command !"
  end

  post "/status" do
    "At your orders !"
  end
end