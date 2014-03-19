require 'rmagick'
require 'base64'

module PhotoApp
  class BasePhotoStorage
    def initialize(opts)
      @opts = opts
      @logger = opts[:logger]
      @upload_dir = opts[:upload_dir]
    end

    def process_and_save_image(photo)
      thumb = generate_thumbnail(@upload_dir, photo)
      save_photo_and_thumbnail(photo, thumb)
    end

    def load_image(oid)
      image_path = get_image(oid)
      img = Magick::Image::read(image_path).first
      "data:image/jpeg;base64,#{Base64.encode64(img.to_blob)}"
    end

    #@return [p_oid, t_oid] of the image
    # - returns the object id of the saved photo and thumbnail
    def save_photo_and_thumbnail(photo, thumbnail)
      raise "Not implemented"
    end

    # Converts object id of the image file to local file path
    def get_image(oid)
      raise "Not implemented"
    end

    private
    def generate_thumbnail(path, name)
      img_orig = Magick::Image::read("#{path}/#{name}").first

      # compute thumbnail dimensions based on aspect ratio
      img_thumb = img_orig.resize_to_fill(48)
      img_thumb.write("#{path}/thumb_#{name}")

      "thumb_#{name}"
    end

  end
end
