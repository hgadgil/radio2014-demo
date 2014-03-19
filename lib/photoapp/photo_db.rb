require 'data_mapper'
require 'dm-timestamps'
require 'dm-validations'

module PhotoApp
  class PhotoDb

    class Photo
      include DataMapper::Resource

      property :id, Serial
      property :name, String, :required => true, :lazy => false
      property :desc, Text, :required => true
      property :photo_object_id, Text, :required => true, :lazy => false
      property :thumb_object_id, Text, :required => true, :lazy => false
      property :owner, String, :required => true, :lazy => false
      property :likes, Integer, :required => true, :lazy => false

      property :created_at, DateTime
      property :updated_at, DateTime

      validates_presence_of :name, :desc, :photo_object_id, :thumb_object_id, :owner, :likes
    end

    def initialize(opts)
      @logger = opts[:logger]
      @db = opts[:db] || raise('PhotoDB not specified')

      DataMapper.setup :default, @db
      DataMapper::auto_upgrade!

      @logger.info("Initialized PhotoDB: #{@db}")
    end

    def add_photo(p_oid, t_oid, owner, name = SecureRandom.uuid, desc = "")
      %w[p_oid t_oid owner].each do |arg|
        val = eval arg
        raise "#{arg} cannot be nil" if val.nil?
      end

      photo = Photo.create(
          #:id => SecureRandom.uuid,
          :name => name,
          :desc => desc,
          :photo_object_id => p_oid,
          :thumb_object_id => t_oid,
          :owner => owner,
          :likes => 0
      )
      @logger.debug("Photo added: #{photo.inspect}")
    end

    def like_photo(photo_id)
      raise 'photo_id cannot be nil' if photo_id.nil?
      instance = Photo.get(id)
      raise "Failed to get instance: #{photo_id}" if instance.nil?

      instance.attributes[:likes] += 1

      try_save_photo(instance)
    end

    def delete_photo(photo_id)
      raise 'photo_id cannot be nil' if photo_id.nil?
      instance = Photo.get(photo_id)
      raise "Failed to get photo: #{photo_id}" if instance.nil?
      raise "Failed to destroy photo: #{instance.inspect}" unless instance.destroy
      @logger.debug("Deleted: #{photo_id}")
    end

    def get_photo(photo_id)
      raise 'photo_id cannot be nil' if photo_id.nil?
      @logger.debug("Get Photo: id = #{photo_id}")
      instance = Photo.get(photo_id)
      raise "Failed to get photo: #{photo_id}" if instance.nil?
      instance
    end

    def get_all_photos
      Photo.all
    end

    def try_save_photo(instance)
      begin
        instance.save
        @logger.debug("Saved: #{instance.inspect}")
      rescue => e1
        @logger.error("Could not save instance: #{instance.name} due to: #{e1}, cleaning up")
        begin
          delete_photo(instance.id)
        rescue => e2
          @logger.error("Could not clean up instance: #{instance.name}")
        end
        raise "Failed to create: #{instance.inspect}"
      end
    end
  end
end