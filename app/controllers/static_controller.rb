class StaticController < ApplicationController
  @@config_path = Rails.root + 'config/config.yml'

  def show_config
    authorize! :read, :application_config
    config = YAML::load(File.read(@@config_path))
    expose config
  end

  def save_config
    authorize! :write, :application_config

    config = YAML::load(File.read(@@config_path)) || {}

    if application_params.include? :header

      if application_params[:header].nil?
        config[:header_url] = nil
      else
        uploader = ImageUploader.new
        uploader.store! params[:header]
        config[:header_url] = uploader.url
      end
    end

    [:title_line_1, :title_line_2].each do |param|
      config[param] = application_params[param] unless application_params[param].nil?
    end

    File.write(@@config_path, config.to_yaml)

    head :no_content
  end

  private
  def application_params
    params.permit :title_line_2, :title_line_1, :header
  end
end