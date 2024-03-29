require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module UppServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :"pt-BR"

    config.action_dispatch.default_headers = nil

    config.time_zone = "America/Sao_Paulo"

    config.autoload_paths += Dir["#{config.root}/app/models/**/"]

    config.rocket_pants.pass_through_errors = true

    config.middleware.use Rack::Deflater

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => :all
      end
    end

    require 'rack/x_session_id'
    require 'rack/compress_requests'

    config.middleware.insert_before "ActionDispatch::Session::RedisStore", Rack::XSessionID
    config.middleware.insert_before "ActionDispatch::Session::RedisStore", CompressedRequests
  end
end
