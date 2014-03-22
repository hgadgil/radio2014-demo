$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))

require 'sinatra'
require 'haml'

require 'photoapp/photo_lib'
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
            :detail => "Error loading Photo Id: #{id}",
            :backtrace => e.backtrace
        }
    return
  end

  haml :main
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

  PhotoApp::PhotoLib.instance.process_new_photo(name, desc)

  redirect "/"
end

post "/like" do
  photo_id = params[:photo_id]
  liked_by = params[:liked_by]
  PhotoApp::PhotoLib.instance.like_photo(photo_id, liked_by)

  redirect "/"
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

