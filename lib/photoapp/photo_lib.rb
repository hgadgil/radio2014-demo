$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..')

require 'singleton'
require 'photoapp/photo_db'
require 'photoapp/logger'
require 'photoapp/storage/local_photo_storage'
require 'photoapp/storage/s3_photo_storage'

module PhotoApp
  class PhotoLib

    include Singleton

    def initialize
      config_file = File.join(File.dirname(__FILE__), '..', '..', 'config', 'photolib.yml')

      puts "Config file: #{config_file}"
      config = {}
      begin
        cfg = YAML.load_file(config_file)
        config = symbolize_keys(cfg)
      end

      puts "Loaded config: #{config.inspect}"

      @logger = config[:logger] = PhotoApp::Logger::StdoutLogger.new(config[:logging][:level])
      @photo_db = PhotoApp::PhotoDb.new(config)

      klass = class_from_string(config[:photo_storage_manager][:implementation])
      @photo_storage_mgr = klass.new(config)
    end

    def process_new_photo(name, desc, input_photo_data_stream, owner)
      p_oid, t_oid = @photo_storage_mgr.process_and_save_image(name, input_photo_data_stream)
      @photo_db.add_photo(p_oid, t_oid, owner, name, desc)
    end

    def load_photo(oid, opts = {})
      @photo_storage_mgr.load_image(oid, opts)
    end

    def get_photo_record(photo_id)
      @photo_db.get_photo(photo_id)
    end

    def get_all_photos(user)
      @photo_db.get_all_photos(user)
    end

    def like_photo(photo_id, liked_by)
      @photo_db.like_photo(photo_id, liked_by)
    end

    def authenticate(username, password)
      @photo_db.authenticate(username, password)
    end

    def register(username, password)
      @photo_db.add_user(username, password)
    end

    private

    # NOTE: Code borrowed from:
    # http://stackoverflow.com/questions/3163641/get-a-class-by-name-in-ruby
    def class_from_string(str)
      str.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end
    end

    def symbolize_keys(hash)
      if hash.is_a? Hash
        new_hash = {}
        hash.each { |k, v| new_hash[k.to_sym] = symbolize_keys(v) }
        new_hash
      else
        hash
      end
    end

  end
end

