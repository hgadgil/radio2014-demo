require 'rmagick'
require 'base64'

module PhotoApp
  class BasePhotoStorage

    CONTENT_TYPE_MAPPING = {
        ".jpg" => "image/jpeg",
        ".jpeg" => "image/jpeg",
        ".png" => "image/png",
    }

    def initialize(opts)
      @opts = opts
      @logger = opts[:logger]
      @upload_dir = opts[:upload_dir]

      @storage_properties = opts[:photo_storage_manager][:properties]
    end

    def process_and_save_image(photo)
      thumb = generate_thumbnail(@upload_dir, photo)
      save_photo_and_thumbnail(photo, thumb)
    end

    def load_image(oid)
      content_type = CONTENT_TYPE_MAPPING[File.extname(oid)]
      raise "Unknown file type: #{File.extname(oid)}" if content_type.nil?

      img = get_image(oid)

      "data:#{content_type};base64,#{Base64.encode64(img.to_blob)}"
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

    def check_required_opts(req_opts)
      missing_opts = req_opts.select { |o| !@storage_properties.has_key? o }
      raise ArgumentError, "Missing options: #{missing_opts.join(', ')}" unless missing_opts.empty?
    end

    private
    def generate_thumbnail(path, name)
      img_orig = Magick::Image::read("#{path}/#{name}").first

      # compute thumbnail dimensions based on aspect ratio
      img_thumb = img_orig.resize_to_fill(128)
      img_thumb.write("#{path}/thumb_#{name}")

      "thumb_#{name}"
    end

  end
end
