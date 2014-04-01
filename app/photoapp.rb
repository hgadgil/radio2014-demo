$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'haml'
require 'will_paginate'
require 'will_paginate/view_helpers/sinatra'

require 'date'
require 'json'

require 'photoapp/photo_lib'

enable :sessions
use Rack::Session::Cookie, :secret => "yummy_cookie", :expire_after => 60*60*3

helpers WillPaginate::Sinatra::Helpers

PHOTO_LIB = PhotoApp::PhotoLib.instance

helpers do
  def show_error(code, detail, exception)
    haml :error, :locals =>
        {
            :code => code,
            :detail => detail,
            :backtrace => exception.backtrace
        }
  end

  def load_thumbnails(all_photos)
    thumbnail_rows = []
    count = 0
    begin
      row = {}
      columns = 0

      all_photos.each do |photo|
        count += 1
        columns += 1
        if columns > THUMBNAILS_PER_ROW
          thumbnail_rows << row
          row = {}
          columns = 0
        end

        row[photo.id] = PHOTO_LIB.load_photo(photo.thumb_object_id)
      end
      thumbnail_rows << row
    rescue => e
      show_error(500, "Error loading photos", e)
    end

    [thumbnail_rows, count]
  end

end

# --- Photo management
THUMBNAILS_PER_ROW = 5

get '/' do
  begin
    @all_photos = PHOTO_LIB.get_all_photos(params["page"] || 1, nil)
    @thumbnail_rows, @count = load_thumbnails(@all_photos)
    haml :home
  rescue => e
    show_error(500, "Failed to load photos", e)
  end
end

get '/my' do
  begin
    @all_photos = PHOTO_LIB.get_all_photos(params["page"] || 1, session[:user])
    @thumbnail_rows, @count = load_thumbnails(@all_photos)
    haml :my
  rescue => e
    show_error(500, "Failed to load photos", e)
  end
end

get '/upload' do
  haml :upload
end

post '/upload' do
  unless params[:file] && (tmpfile_stream = params[:file][:tempfile])
    haml :upload
  end

  desc = params[:desc].length == 0 ? "No Description" : params[:desc]
  name = "#{SecureRandom.uuid}#{File.extname(params[:file][:filename])}"
  input_photo = tmpfile_stream.read

  STDOUT.puts ">>> Uploading: #{params[:file][:filename]} as #{name}"
  STDOUT.puts ">>> \t-Desc: #{desc}"
  STDOUT.puts ">>> \t-input_photo: #{input_photo.size}"

  PHOTO_LIB.process_new_photo(name, desc, input_photo, session[:user])

  redirect "/"
end

post '/like' do
  photo_id = params[:photo_id]
  liked_by = params[:liked_by]
  PHOTO_LIB.like_photo(photo_id, liked_by)

  redirect "/show/#{photo_id}"
end

get '/show/:id' do
  id = params[:id]

  begin
    @record = PHOTO_LIB.get_photo_record(id)
    @uploaded_at = @record.created_at.strftime("%D %r %Z")
  rescue => e
    show_error(404, "Invalid Photo Id: #{id}", e)
  end

  begin
    @photo = PHOTO_LIB.load_photo(@record.photo_object_id)
  rescue => e
    show_error(500, "Error loading Photo Id: #{id}", e)
  end

  haml :show
end

# --- API - for app access

get '/images' do
  my_images_only = params["my"]
  user = my_images_only ? session[:user] : nil

  records = PHOTO_LIB.get_all_photos(params["page"] || 1, user)
  result = {
      :current_page => records.current_page,
      :per_page => records.per_page,
      :total_entries => records.total_entries,
      :total_pages => records.total_pages,
      :records => {}
  }
  records.each do |rec|
    result[:records][rec.id] = {:name => rec.name, :desc => rec.desc, :owner => rec.owner, :created_at => rec.created_at}
  end

  response.headers['Content-Type'] = 'application/json'
  result.to_json
end


get '/image/:id' do
  id = params[:id]
  thumb = params["thumb"]

  begin
    @record = PHOTO_LIB.get_photo_record(id)
  rescue => e
    show_error(404, "Invalid Photo Id: #{id}", e)
  end

  begin
    oid = thumb ? @record.thumb_object_id : @record.photo_object_id
    type, blob = PHOTO_LIB.load_photo(oid, {:raw => true})
    response.headers['Content-Type'] = type
    blob
  rescue => e
    show_error(500, "Error loading Photo Id: #{id}", e)
  end
end

# --- Auth

get '/register' do
  haml :register
end

post '/register' do
  begin
    PHOTO_LIB.register(params[:username], params[:password])
    puts "Registered: #{params[:username]}"
    redirect "/login"
  rescue => e
    show_error(500, "Failed to register: #{e.message}", e)
  end
end

get '/login' do
  haml :login
end

post '/login' do
  begin
    PHOTO_LIB.authenticate(params[:username], params[:password])
    puts "Logged in: #{params[:username]}"
    session[:user] = params[:username]
    redirect '/'
  rescue => e
    show_error(401, "Login failed: #{e.message}", e)
  end
end

get '/logout' do
  session[:user] = nil
  redirect '/login'
end
