$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))

require 'sinatra'
require 'haml'

require 'photoapp/photo_lib'

enable :sessions
use Rack::Session::Cookie, :secret => "yummy_cookie"

# --- Photo management

get "/" do
  begin
    @all_photos = PhotoApp::PhotoLib.instance.get_all_photos
  rescue => e
    haml :error, :locals =>
        {
            :code => 500,
            :detail => "Failed to load photos",
            :backtrace => e.backtrace
        }
    return
  end

  THUMBNAILS_PER_ROW = 5

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
    haml :error, :locals =>
        {
            :code => 500,
            :detail => "Error loading Photos",
            :backtrace => e.backtrace
        }
    return
  end

  haml :home
end

get "/upload" do
  haml :upload
end

post "/upload" do
  unless params[:file] && (tmpfile = params[:file][:tempfile])
    return haml(:upload)
  end

  desc = params[:desc].length == 0 ? "No Description" : params[:desc]
  name = "#{SecureRandom.uuid}#{File.extname(params[:file][:filename])}"

  STDOUT.puts ">>> Uploading: #{params[:file][:filename]} as #{name}"
  STDOUT.puts ">>> \t-Desc: #{desc}"

  File.open(File.join(PhotoApp::PhotoLib.instance.upload_dir, name), "wb") { |f|
    f.write(tmpfile.read)
  }

  PhotoApp::PhotoLib.instance.process_new_photo(name, desc, session[:user])

  redirect "/"
end

post "/like" do
  photo_id = params[:photo_id]
  liked_by = params[:liked_by]
  PhotoApp::PhotoLib.instance.like_photo(photo_id, liked_by)

  redirect "/show/#{photo_id}"
end

get "/show/:id" do
  id = params[:id]

  begin
    @record = PhotoApp::PhotoLib.instance.get_photo_record(id)
  rescue => e
    haml :error, :locals =>
        {
            :code => 404,
            :detail => "Invalid Photo Id: #{id}",
            :backtrace => e.backtrace
        }
    return
  end

  begin
    @photo = PhotoApp::PhotoLib.instance.load_photo(@record.photo_object_id)
  rescue => e
    haml :error, :locals =>
        {
            :code => 500,
            :detail => "Error loading Photo Id: #{id}",
            :backtrace => e.backtrace
        }
    return
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
    flash[:notice] = "Registered: #{params[:username]}"
    redirect "/login"
  rescue => e
    haml :error, :locals =>
        {
            :code => 500,
            :detail => "Failed to register: #{e.message}",
            :backtrace => e.backtrace
        }
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
    haml :error, :locals =>
        {
            :code => 500,
            :detail => "Login failed: #{e.message}",
            :backtrace => e.backtrace
        }
  end
end

get '/logout' do
  session[:user] = nil
  redirect '/login'
end
