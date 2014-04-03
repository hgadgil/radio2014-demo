#Demo App for RADIO 2014

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

    rackup

## Configuration file

The configuration is stored in <code>config/photolib.yml</code> file.

	logging:
      level: debug

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

#### Using Marketplace DB service

To use a marketplace subscribed DB instance, provide the service type and service name in a bound_db config block
as follows:

    bound_db:
      type: "cleardb"
      name: "photobox"

Once a DB instance is bound to the app, the credentials appear in the <code>VCAP_SERVICES</code> environment variable.
E.g.:

    {
      "cleardb": [
        {
          "name": "photobox",
          "label": "cleardb",
          "tags": [
            "relational",
            "Data Store",
            "mysql"
          ],
          "plan": "spark",
          "credentials": {
            "jdbcUrl": "jdbc:mysql://u12345678:p12345678@us-cdbr-east-05.cleardb.net:3306/ad_f12345",
            "uri": "mysql://u12345678:p12345678@us-cdbr-east-05.cleardb.net:3306/ad_f12345?reconnect=true",
            "name": "ad_fa953d9a56f48b6",
            "hostname": "us-cdbr-east-05.cleardb.net",
            "port": "3306",
            "username": "u12345678",
            "password": "p12345678"
          }
        }
      ]
    }


The DB will automatically use the service instance matching the <code>type</code> and <code>name</code> from the list
of bound services.


### AWS configuration

    photo_storage_manager:
      implementation: "PhotoApp::S3PhotoStorage"
      properties:
        aws_access_key_id: "<ACCESS_KEY_ID>"
        aws_secret_access_key: "<SECRET_ACCESS_KEY>"
        region: "<BUCKET_REGION>"
        bucket: "<BUCKET_NAME>"

