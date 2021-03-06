require 'fileutils'
require 'photoapp/storage/base_photo_storage'

module PhotoApp
  class LocalPhotoStorage < PhotoApp::BasePhotoStorage

    REQ_OPTS = %w(local_photo_store).map { |o| o.to_sym}

    def initialize(opts)
      super(opts)
      check_required_opts(REQ_OPTS)

      @local_photo_store = @storage_properties[:local_photo_store]

      if @local_photo_store.match(/^\//).nil?
        @local_photo_store = File.join(File.dirname(__FILE__), '../../..', @local_photo_store)
      end

      @logger.info("Setting Local Photo Store to: #{@local_photo_store}")

      unless Dir.exists?(@local_photo_store)
        @logger.debug("Creating photo store folder...")
        FileUtils::mkdir_p(@local_photo_store)
      end
    end

    def save_photo_and_thumbnail(photo_name, photo_blob, thumb_name, thumb_blob)
      p_oid = "#{@local_photo_store}/#{photo_name}"
      t_oid = "#{@local_photo_store}/#{thumb_name}"

      photo_blob.write(p_oid)
      thumb_blob.write(t_oid)

      [p_oid, t_oid]
    end

    def get_image(oid)
      Magick::Image::read(oid).first
    end

    def delete_image(oid)
      FileUtils.rm oid, :force => true
    end

  end
end
