require 'data_mapper'
require 'dm-timestamps'
require 'dm-validations'

require 'bcrypt'
require 'will_paginate'
require 'will_paginate/data_mapper'

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

    def delete_photo(photo_id, current_user)
      raise 'photo_id cannot be nil' if photo_id.nil?
      @logger.debug("Deleting photo: #{photo_id}")

      instance = Photo.get(photo_id)
      raise "Failed to get photo: #{photo_id}" if instance.nil?

      p_oid = instance.photo_object_id
      t_oid = instance.thumb_object_id

      @logger.debug("Deleting: #{instance.inspect}")
      @logger.debug("Owner: #{instance.owner}, Requestor: #{current_user} - OK to delete: #{current_user.eql? instance.owner}")

      raise "Cannot delete photo as current user(#{current_user}) is not the owner(#{instance.owner}) of photo" unless current_user.eql? instance.owner
      raise "Could not delete photo likes" unless instance.likes.destroy
      raise "Could not delete photo" unless instance.destroy

      [p_oid, t_oid]
    end

    def get_photo(photo_id)
      raise 'photo_id cannot be nil' if photo_id.nil?
      @logger.debug("Get Photo: id = #{photo_id}")
      instance = Photo.get(photo_id)
      raise "Failed to get photo: #{photo_id}" if instance.nil?
      instance
    end

    def get_all_photos(opts = {})
      page_num = opts[:page_num]
      user = opts[:user]
      paginate = opts[:paginate]

      @logger.debug("Getting Page: #{page_num} for user: #{user}")

      result = nil
      if user.nil?
        result = Photo.all(:order => :created_at.desc)
      else
        result = Photo.all(:owner => user, :order => :created_at.desc)
      end

      return result unless paginate

      result.paginate(:page => page_num, :per_page => 10)
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