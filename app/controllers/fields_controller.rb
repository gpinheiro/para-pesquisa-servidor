class FieldsController < ApplicationController
  load_and_authorize_resource

  def index
    section = Section.find(params[:section_id])
    expose section.fields
  end

  def show
    field = Field.find(params[:id])
    expose field
  end

  def create
    section = Section.find(params[:section_id])
    field = section.fields.create! field_params
    json_set_status :created
    expose :field_id => field.id
  end

  def update
    field = Field.find(params[:id])

    if params[:type]
      field = field.becomes!(Kernel.const_get(params[:type]))
    end

    field_parameters = field_params()
    field.options = field_parameters.extract!(:options) unless field_parameters[:options].nil?
    field.update! field_params
    field.save
    json_set_status :no_content
  end

  def destroy
    field = Field.find(params[:id])
    field.destroy
    json_set_status :no_content
  end

  def update_order
    params[:order].each_with_index do |id, index|
      s = Field.find(id)
      s.order = index + 1
      s.save
    end

    json_set_status :no_content
  end

  private
    def field_params
      params.permit :label, :description, :type, :layout, :read_only, :identifier, :options => [:label, :value], :validations => [:required, :range], :actions => [:when => [], :enable => [], :disable => []]
    end
end
