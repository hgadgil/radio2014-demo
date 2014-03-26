require 'aws-sdk'

require 'photoapp/storage/base_photo_storage'

module PhotoApp
  class S3PhotoStorage < PhotoApp::BasePhotoStorage

    REQ_OPTS = %w(bucket aws_access_key_id aws_secret_access_key region).map { |o| o.to_sym}

    def initialize(opts)
      super(opts)

      check_required_opts(REQ_OPTS)
      @bucket = @storage_properties[:bucket]

      AWS.config(
          access_key_id: @storage_properties[:aws_access_key_id],
          secret_access_key: @storage_properties[:aws_secret_access_key],
          region: @storage_properties[:region]
      )
      @s3 = AWS::S3.new
    end

    def save_photo_and_thumbnail(photo_name, photo_blob, thumb_name, thumb_blob)
      p_oid = upload_image_to_s3(photo_name, photo_blob)
      t_oid = upload_image_to_s3(thumb_name, thumb_blob)

      [p_oid, t_oid]
    end

    def get_image(oid)
      @logger.debug("Reading Object: #{oid}")

      data = @s3.buckets[@bucket].objects[oid].read
      @logger.debug("Read #{data.size} bytes")
      Magick::Image::from_blob(data).first
    end

    private

    def upload_image_to_s3(image_name, image_blob)
      @logger.debug("Uploading: #{image_name}")
      @s3.buckets[@bucket].objects[image_name].write(image_blob.to_blob)

      image_name
    end
  end
end