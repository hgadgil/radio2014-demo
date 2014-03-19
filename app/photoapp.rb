$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))

require 'sinatra'
require 'haml'

require 'photoapp/photo_lib'
get "/" do
  begin
    @output = PhotoApp::PhotoLib.instance.get_all_photos
  rescue => e
    @output = nil
    @backtrace = e.backtrace
  end

  if @output
    haml :main
  else
    haml :error, :locals =>
        {
            :code => 500,
            :detail => 'Failed to get photos',
            :backtrace => @backtrace
        }
  end
end

#get "/list/:page" do
#
#  haml :list
#end

get "/upload" do
  haml :upload
end

post "/upload" do
  unless params[:file] &&
      (tmpfile = params[:file][:tempfile]) &&
      (name = params[:file][:filename])
    return haml(:upload)
  end

  desc = params[:desc]

  STDERR.puts "Uploading: #{name}"

  while blk = tmpfile.read(65536)
    File.open(File.join(PhotoApp::PhotoLib.instance.upload_dir, name), "wb") { |f| f.write(blk) }
  end

  PhotoApp::PhotoLib.instance.process_new_photo(name, desc)

  redirect "/"
end

get "/show/:id" do
  id = params[:id]

  begin
    @output = PhotoApp::PhotoLib.instance.get_photo_record(id).inspect
  rescue => e
    @output = nil
    @backtrace = e.backtrace
  end

  if @output
    haml :show
  else
    haml :error, :locals =>
        {
            :code => 404,
            :detail => "Photo Id: #{id} is invalid",
            :backtrace => @backtrace
        }
  end
end

