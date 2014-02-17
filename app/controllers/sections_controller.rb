class SectionsController < ApplicationController
  load_and_authorize_resource

  def index
    form = Form.find(params[:form_id])
    expose form.sections
  end

  def show
    section = Section.find(params[:id])
    expose section
  end

  def create
    form = Form.find(params[:form_id])
    section = form.sections.create! section_params
    head :created
    expose :section_id => section.id
  end

  def update
    section = Section.find(params[:id])
    section.update! section_params
    head :no_content
  end

  def destroy
    section = Section.find(params[:id])
    section.destroy
    head :no_content
  end

  def update_order
    params[:order].each_with_index do |id, index|
      s = Section.find(id)
      s.order = index + 1
      s.save
    end

    head :no_content
  end

  private
  def section_params
    params.permit :name, :order
  end
end
