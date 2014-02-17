require 'spec_helper'

describe StaticController do
  let(:default_params) { {:title_line_1 => 'Agentes da', :title_line_2 => 'Transformação', :header_url => '/uploads/original/logo.jpg'} }

  describe 'successful requests' do
    before :each do
      @user = log_in(:api)

      File.stubs(:read).returns(default_params.to_yaml)
    end

    it 'should return the values defined in config.yml' do
      get :show_config, use_route: :static
      assert_response :success
      json_response['title_line_1'] = default_params['title_line_1']
      json_response['title_line_2'] = default_params['title_line_2']
      json_response['header_url'] = default_params['header_url']
    end

    it 'should allow users with API access to modify the contents of the config' do
      post :save_config, default_params.merge(use_route: :static)
      assert_response :no_content

      get :show_config, use_route: :static
      default_params.each { |key, value| json_response[key.to_s].should == value }
    end

    it 'should allow an image be uploaded to header' do
      post :save_config, {header: fixture_file_upload('logo.jpg', 'image/jpg'), use_route: :static}
      assert_response :no_content

      get :show_config, use_route: :static
      json_response['header_url'].should match_regex(/logo\.jpg$/)
    end

    it 'should remove the image if the header param is blank' do
      default_params[:header_url] = nil
      post :save_config, header: nil, use_route: :static
      assert_response :no_content
    end

  end
end