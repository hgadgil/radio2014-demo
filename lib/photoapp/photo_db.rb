require 'data_mapper'
require 'dm-timestamps'
require 'dm-validations'

require 'bcrypt'

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

      has n, :likes

      property :created_at, DateTime
      property :updated_at, DateTime

      validates_presence_of :name, :desc, :photo_object_id, :thumb_object_id, :owner
    end

    class Like
      include DataMapper::Resource

      property :id, Serial
      property :liked_by, String, :required => true, :lazy => false

      belongs_to :photo
    end


    class User
      include DataMapper::Resource
      include BCrypt

      property :id, Serial
      property :username, String
      property :password, BCryptHash

      def authenticate(attempted_password)
        if self.password == attempted_password
          true
        else
          false
        end
      end
    end


    def initialize(opts)
      @logger = opts[:logger]
      @db = opts[:db] || raise('PhotoDB not specified')

      DataMapper.setup :default, @db
      DataMapper.finalize.auto_upgrade!

      @logger.info("Initialized PhotoDB: #{@db}")
    end

    def add_photo(p_oid, t_oid, owner, name, desc)
      %w[p_oid t_oid owner name].each do |arg|
        val = eval arg
        raise "#{arg} cannot be nil" if val.nil?
      end

      photo = Photo.create(
          :name => name,
          :desc => desc,
          :photo_object_id => p_oid,
          :thumb_object_id => t_oid,
          :owner => owner
      )
      @logger.debug("Photo added: #{photo.inspect}")
    end

    def like_photo(photo_id, liked_by)
      raise 'photo_id cannot be nil' if photo_id.nil?
      photo = Photo.get(photo_id)
      raise "Failed to get instance: #{photo_id}" if photo.nil?

      old_like = photo.likes.first(:liked_by => liked_by)
      unless old_like.nil?
        @logger.warn("Photo: #{photo_id} already liked by: #{liked_by}")
        return
      end

      like = photo.likes.create(:liked_by => liked_by)

      @logger.debug("Like registered: #{like.inspect}")
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

    def get_all_photos(user)
      if user.nil?
        Photo.all(:order => :created_at.desc)
      else
        Photo.all(:owner => user, :order => :created_at.desc)
      end
    end

    # -- Auth

    def add_user(username, password)
      %w[username password].each do |arg|
        val = eval arg
        raise "#{arg} cannot be nil" if val.nil?
      end

      old_user = User.first(:username => username)
      puts "Found old user= #{old_user.inspect}"
      raise "Username already exists" unless old_user.nil?

      user = User.create(:username => username, :password => password)
      @logger.debug("Registered user: #{user.inspect}")
    end

    def authenticate(user, pass)
      user = User.first(username: user)

      raise "User does not exist" if user.nil?
      raise "Unauthorized" unless user.authenticate(pass)
    end

  end
end