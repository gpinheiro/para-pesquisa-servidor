class TextsController < ApplicationController
  load_and_authorize_resource

  def show
    expose Text.find(params[:id])
  end

  def index
    expose Text.all
  end

  def create
    text = Text.create! text_params
    json_set_status :created
    expose :text_id => text.id
  end

  def update
    text = Text.find(params[:id])
    text.update(text_params)
    head :no_content
  end

  def destroy
    Text.find(params[:id]).destroy
    head :no_content
  end

  private
  def text_params
    params.permit :title, :subtitle, :content
  end
end
