$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'haml'

require 'photoapp/photo_lib'

enable :sessions

use Rack::Session::Cookie, :secret => "yummy_cookie", :expire_after => 60*60*3

helpers do
  def show_error(code, detail, exception)
    haml :error, :locals =>
        {
            :code => code,
            :detail => detail,
            :backtrace => exception.backtrace
        }
  end
end

# --- Photo management
THUMBNAILS_PER_ROW = 5

get '/' do
  begin
    @all_photos = PhotoApp::PhotoLib.instance.get_all_photos
  rescue => e
    show_error(500, "Failed to load photos", e)
  end

  @thumbnail_rows = []
  @count = 0
  begin
    row = {}
    columns = 0

    @all_photos.each do |photo|
      @count += 1
      columns += 1
      if columns > THUMBNAILS_PER_ROW
        @thumbnail_rows << row
        row = {}
        columns = 0
      end

      row[photo.id] = PhotoApp::PhotoLib.instance.load_photo(photo.thumb_object_id)
    end
    @thumbnail_rows << row
  rescue => e
    show_error(500, "Error loading photos", e)
  end

  haml :home
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

  PhotoApp::PhotoLib.instance.process_new_photo(name, desc, input_photo, session[:user])

  redirect "/"
end

post '/like' do
  photo_id = params[:photo_id]
  liked_by = params[:liked_by]
  PhotoApp::PhotoLib.instance.like_photo(photo_id, liked_by)

  redirect "/show/#{photo_id}"
end

get '/show/:id' do
  id = params[:id]

  begin
    @record = PhotoApp::PhotoLib.instance.get_photo_record(id)
  rescue => e
    show_error(404, "Invalid Photo Id: #{id}", e)
  end

  begin
    @photo = PhotoApp::PhotoLib.instance.load_photo(@record.photo_object_id)
  rescue => e
    show_error(500, "Error loading Photo Id: #{id}", e)
  end

  haml :show
end

# --- Auth

get '/register' do
  haml :register
end

post '/register' do
  begin
    PhotoApp::PhotoLib.instance.register(params[:username], params[:password])
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
    PhotoApp::PhotoLib.instance.authenticate(params[:username], params[:password])
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
