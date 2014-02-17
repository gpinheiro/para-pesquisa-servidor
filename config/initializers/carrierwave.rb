if Rails.env.test? or Rails.env.development? or ENV['AWS_ACCESS_KEY_ID'].nil? or ENV['AWS_SECRET_ACCESS_KEY'].nil?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
else
  CarrierWave.configure do |config|
    config.fog_credentials = {
        :provider => 'AWS',
        :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }

    config.storage = :fog
    config.fog_directory = ENV['AWS_IMAGE_BUCKET']
  end
end