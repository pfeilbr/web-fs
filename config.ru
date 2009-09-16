require 'appengine-rack'
AppEngine::Rack.configure_app(          
    :application => "web-fs",           
    :version => 1)
require 'app'
run Sinatra::Application
