class SubmissionsController < ApplicationController
  load_and_authorize_resource

  def index
    listing = Submission.where(:form_id => params[:form_id])

    listing = datetime_filters(listing)

    unless params[:by_status].nil?
      listing = listing.where(:status => params[:by_status])
    end

    expose listing.paginate(:page => params[:page]), each_serializer: FullSubmissionSerializer
  end

  def show
    expose Submission.find(params[:id])
  end

  def create
    form = Form.find(params[:form_id])

    raise 'Este formulário utiliza submissões pré-cadastradas, não é possível criar uma nova manualmente.' if form.allow_new_submissions == false

    form.update(allow_new_submissions: true) if form.allow_new_submissions.nil?

    Submission.transaction do
      assignment = Assignment.where(user_id: current_user, form_id: params[:form_id]).first

      raise 'O usuário não está designado para usar esse formulário' if assignment.nil?

      raise 'Este usuário já passou da sua meta' if assignment.submissions.count >= assignment.quota

      submission = form.submissions.create!(user: current_user, form_id: params[:form_id], assignment: assignment)

      submission.answer(params[:answers]) unless params[:answers].nil?

      submission.log.create! action: 'started', user: current_user, date: params[:started_at] || DateTime.now

      submission.save

      expose :submission_id => submission.id
    end
  end

  def update
    submission = Submission.find(params[:id])

    submission.status = params[:status] unless params[:status].nil?

    if submission.status == 'waiting_approval' and submission.log.find_by_action('started').nil?
      submission.log.create! action: 'started', date: params[:started_at] || DateTime.now, user: current_user
    end

    submission.answer(params[:answers]) unless params[:answers].nil?

    submission.review(current_user, params[:corrections]) unless params[:corrections].nil?

    submission.save

    head :no_content
  end

  def destroy
    submission = Submission.find(params[:id])
    submission.destroy

    head :no_content
  end

  def create_correction
    submission = Submission.find(params[:submission_id])

    correction = submission.corrections.new
    correction.field_id = correction_params[:field_id]
    correction.message = correction_params[:message]
    correction.user = current_user
    correction.save

    head :created

    expose :correction_id => correction.id
  end

  def update_correction
    correction = Correction.find(params[:id])

    correction.update! correction_params

    head :no_content
  end

  def delete_correction
    correction = Correction.find(params[:id])
    correction.destroy

    head :no_content
  end

  def reschedule
    submission = Submission.find(params[:id])

    reason = StopReason.find(params[:reason_id])

    if reason.reschedule?
      submission.log.create! action: 'rescheduled', user: current_user, date: params[:date], stop_reason: reason
      submission.status = 'rescheduled'
      submission.save
    else
      submission.log.create! action: 'canceled', user: current_user, date: params[:date], stop_reason: reason
      submission.status = 'canceled'
      submission.save
    end

    head :no_content
  end

  def moderate
    submission = Submission.find(params[:id])

    if params[:submission_action] == 'approve'
      submission.approve current_user, params[:date]
    else
      submission.reprove current_user, params[:date]
    end

    head :no_content
  end

  def reset
    submission = Submission.find(params[:id])
    submission.reset current_user

    json_set_status :no_content
  end

  def reset_by_mod
    user = User.where(:id => params[:mod_id], :role => 'mod').first
    raise ActiveRecord::RecordNotFound.new('Moderador não encontrado') if user.nil?

    Assignment.where(:mod_id => user.id).each do |assignment|
      assignment.user.submissions.each { |submission| submission.reset(current_user) }
    end

    json_set_status :no_content
  end

  def swap
    user_from = User.find(params[:user_id_from])
    user_to = User.find(params[:user_id_to])

    pivot = user_to.submissions.pluck(:id)

    Submission.where(:user_id => user_from.id).update_all(user_id: user_to.id)
    pivot.each { |submission_id| Submission.find(submission_id).update!(user: user_from) }

    json_set_status :no_content
  end

  def transfer_by_form_id
    submissions = Submission.where(user_id: params[:user_id_from], form_id: params[:form_id])

    user_to = User.find(params[:user_id_to])

    submissions.each { |submission| submission.transfer(user_to, params[:date]) }

    json_set_status :no_content
  end

  def transfer_by_submission_id
    submissions = Submission.find(params[:submissions_ids])

    user = User.find(params[:user_id])

    if user.role != 'agent'
      raise "Não é possível transferir submissões de usuários que não são pesquisadores."
    end

    submissions.each { |submission| submission.transfer(user, params[:date]) }

    user.assignment.first.update!(quota: user.submissions.count) unless user.assignment.first.quota == 0

    json_set_status :no_content
  end

  private
  def listing_params
    params.permit :created_from, :created_to, :updated_from, :updated_to
  end

  def submissions_params
    params.permit :answers, :status
  end

  def correction_params
    params.permit :user_id, :message, :field_id
  end
end