require 'spec_helper'

describe SubmissionsController do
  default_version 1
  let(:default_params) { {use_route: :submissions} }

  context 'successful requests' do

    before do
      @user = log_in :api
    end

    it 'should display the list without any filter' do
      get :index, default_params
      expect(response).to be_paginated_resource
      expect(response).to have_exposed Submission.all
    end

    it 'should display only submissions created_from a date' do
      reference_time = DateTime.now - 10.seconds
      invalid_submission = Submission.create! created_at: DateTime.now - 20.seconds # Creation order is important
      valid_submission = Submission.create! created_at: reference_time

      get :index, default_params.merge(created_from: reference_time.to_s)
      expect(json_response[0]['id']).to eq(valid_submission.id)
      expect(json_response.length).to eq(1)
    end

    it 'should reset a submission' do
      submission = Fabricate :submission
      submission.answers = {}
      post :reset, default_params.merge(:submission_id => submission.id)
    end
  end
end