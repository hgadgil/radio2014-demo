

#Demo App for RADIO 2014
==============

## Requirements

Requires ImageMagick to be installed

On OSX:

    brew install imagemagick

On Ubuntu:

    apt-get install imagemagick

## To Install

    git clone <repo>
    bundle install

## To Run

    ruby ./app/photoapp.rb

## Configuration file

The configuration is stored in <code>config/photolib.yml</code> file.

	logging:
      level: debug

    upload_dir: "/tmp"

    db: sqlite3:photodb.db

    photo_storage_manager:
      implementation: "PhotoApp::LocalPhotoStorage"
      properties:
        local_photo_store: "photolibstore"

### DB Configuration

To switch to mysql, provide the connection string to the <code>db</code> option:
E.g.:

    db: "mysql://<USER>:<PASSWORD>@<HOST>:<PORT>/<DB_NAME>"

####NOTE:

Correct firewall rules must be setup to allow access to the mysql instance

### AWS configuration

    photo_storage_manager:
      implementation: "PhotoApp::S3PhotoStorage"
      properties:
        aws_access_key_id: "<ACCESS_KEY_ID>"
        aws_secret_access_key: "<SECRET_ACCESS_KEY>"
        region: "<BUCKET_REGION>"
        bucket: "<BUCKET_NAME>"
