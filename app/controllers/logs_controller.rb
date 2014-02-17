class LogsController < ApplicationController
  load_and_authorize_resource

  def index
    listing = Log.joins(:user).order('id DESC')
    listing = datetime_filters(listing, nil, 'logs')

    unless params[:user_id].nil?
      listing = listing.where(:user_id => params[:user_id])
    end

    expose listing.paginate(:page => params[:page]), each_serializer: FullLogSerializer
  end
end