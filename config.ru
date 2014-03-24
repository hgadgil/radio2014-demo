$LOAD_PATH.unshift("./app")

require './app/photoapp'

run Sinatra::Application
