require 'photoapp/storage/base_photo_storage'

module PhotoApp
  class S3PhotoStorage < PhotoApp::BasePhotoStorage

    def initialize(opts)
      super(opts)
      @s3_credentials = opts[:s3_credentials]
    end

    def save_photo_and_thumbnail(photo, thumb)
      #TODO: Upload to S3 storage

      p_oid = upload_image_to_s3(photo)
      t_oid = upload_image_to_s3(thumb)

      [p_oid, t_oid]
    end

    private

    def upload_image_to_s3(image)
      raise 'not implemented yet!'
    end
  end
end