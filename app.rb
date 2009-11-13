# appcfg.rb gem install 
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'appengine-apis/datastore'
require 'json'
require 'mime/types'
require 'base64'
require 'open-uri'

require 'appengine-apis/urlfetch'
Net::HTTP = AppEngine::URLFetch::HTTP


class Sinatra::Reloader < Rack::Reloader
  def safe_load(file, mtime, stderr = $stderr)
    ::Sinatra::Application.reset!
    super
  end
end

configure :development do
    use Sinatra::Reloader
    use Sinatra::ShowExceptions
end

DataMapper.setup(:default, "appengine://auto")

class Shout
  include DataMapper::Resource
  
  property :id, Serial
  property :message, Text
end

class FileItem
  include DataMapper::Resource
  
  property :id, Serial
  property :path, String
  property :contents, Text
end

set :environment, :development

configure do
  FS_PREFIX = 'fs'
  FS_PATTERN = "/#{FS_PREFIX}/*"
end

# Make sure our template can use <%=h
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/proxy/*' do
  CLIENT.get_content(params[:splat].first)
end

get '/' do
  #@files = AppEngine::Datastore::Query.new('File').fetch
  @files = FileItem.all
  erb :index
end

get FS_PATTERN do
  path = params[:splat].first
  #files = AppEngine::Datastore::Query.new('File').filter(:path, :==, path).fetch
  files = FileItem.all(:path => path)
  
  # found a match
  if files.size > 0
    file = files[0]
    mime_types = MIME::Types.of(path)
    
    # mime type found
    if mime_types.size > 0
      content_type MIME::Types.of(path).first.content_type
    else
      # default mime type
      content_type 'text/html'
    end
    
    #file[:contents]
    Base64.decode64(file.contents)
  else
    "File at path \"#{path}\" not found"
  end
  
end

put FS_PATTERN do
  redirect '/'
end

post FS_PATTERN do
  path = params[:splat]
  path = (path.is_a? Array) ? path.first : path
  #file = AppEngine::Datastore::Entity.new('File')
  #file[:path] = path
  #file_contents_blob = AppEngine::Datastore::Blob.new(params[:datafile][:tempfile].read)
  #file.set_property(:contents, file_contents_blob)
  #AppEngine::Datastore.put file
  FileItem.create(:path => path, :contents => Base64.encode64(params[:datafile][:tempfile].read) )
  redirect '/'
end

delete FS_PATTERN do
  path = params[:splat].first
  FileItem.all(:path => path).first.destroy
  redirect '/'
end