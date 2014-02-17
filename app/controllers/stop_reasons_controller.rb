class StopReasonsController < ApplicationController
  load_and_authorize_resource

  def index
    form = Form.find(params[:form_id])
    expose form.stop_reasons
  end

  def show
    expose StopReason.find(params[:id])
  end

  def create
    form = Form.find(params[:form_id])
    reason = form.stop_reasons.create! stop_reasons_params
    head :created
    expose :reason_id => reason.id
  end

  def update
    reason = StopReason.find(params[:id])
    reason.update! stop_reasons_params
    head :no_content
  end

  def destroy
    StopReason.delete(params[:id])
    head :no_content
  end

  private

    def stop_reasons_params
      params.permit :reason, :reschedule
    end
end
