require 'RMagick'
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

      @storage_properties = opts[:photo_storage_manager][:properties]
    end

    def process_and_save_image(photo_name, input_photo)
      photo_blob, thumb_blob = generate_thumbnail(input_photo)
      save_photo_and_thumbnail(photo_name, photo_blob, "thumb_#{photo_name}", thumb_blob)
    end

    def load_image(oid, opts = {})
      content_type = CONTENT_TYPE_MAPPING[File.extname(oid)]
      raise "Unknown file type: #{File.extname(oid)}" if content_type.nil?

      img = get_image(oid)

      return [content_type, img.to_blob] if opts[:raw]

      "data:#{content_type};base64,#{Base64.encode64(img.to_blob)}"
    end

    #@return [p_oid, t_oid] of the image
    # - returns the object id of the saved photo and thumbnail
    def save_photo_and_thumbnail(photo_name, photo_blob, thumb_name, thumb_blob)
      raise "Not implemented"
    end

    # Converts object id of the image file to local file path
    def get_image(oid)
      raise "Not implemented"
    end

    def delete_image(oid)
      raise "Not implemented"
    end

    def check_required_opts(req_opts)
      missing_opts = req_opts.select { |o| !@storage_properties.has_key? o }
      raise ArgumentError, "Missing options: #{missing_opts.join(', ')}" unless missing_opts.empty?
    end

    private

    def generate_thumbnail(input_photo)
      img_orig = Magick::Image::from_blob(input_photo).first

      # resize original image if its > 800x600
      img_orig = img_orig.resize_to_fill(800) if img_orig.x_resolution > 800 || img_orig.y_resolution > 600

      # compute thumbnail dimensions based on aspect ratio
      img_thumb = img_orig.resize_to_fill(128)

      [img_orig, img_thumb]
    end

  end
end
