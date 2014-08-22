# Be sure to restart your server when you modify this file.
UppServer::Application.config.session_store :redis_store, :key => 'session_id', :redis_server => ENV['REDIS_SESSION_URI'] || 'redis://localhost:6379/0/session'

Rails.cache.delete('export_job_rxunning') unless File.basename($0) == 'rake'