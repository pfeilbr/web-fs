require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'appengine-apis/datastore'
require 'json'
require 'mime/types'

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

get '/' do
  @files = AppEngine::Datastore::Query.new('File').fetch
  erb :index
end

get FS_PATTERN do
  path = params[:splat].first
  files = AppEngine::Datastore::Query.new('File').filter(:path, :==, path).fetch
  
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
    
    file[:contents]
  else
    "File at path \"#{path}\" not found"
  end
  
end

put FS_PATTERN do
end

post FS_PATTERN do
  path = params[:splat]
  path = (path.is_a? Array) ? path.first : path
  file = AppEngine::Datastore::Entity.new('File')
  file[:path] = path
  file_contents_blob = AppEngine::Datastore::Blob.new(params[:datafile][:tempfile].read)
  file.set_property(:contents, file_contents_blob)
  AppEngine::Datastore.put file
  redirect '/'
end

delete FS_PATTERN do
end