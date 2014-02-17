class StatisticsController < ApplicationController
  skip_authorization_check

  def global
    submissions = Submission.all

    statistics = Hash[Submission::STATUS.map do |status|
      [status, submissions.where(:status => status).count] unless status == 'new'
    end]

    statistics['total_filled'] = submissions.where('status != ?', 'new').count
    statistics['total'] = submissions.count

    statistics['form_count'] = Form.count
    statistics['user_count'] = User.count

    expose statistics
  end

  def form
    form = Form.find(params[:form_id])
    submissions = form.submissions

    statistics = Hash[Submission::STATUS.map do |status|
      [status, submissions.where(:status => status).count] unless status == 'new'
    end]

    statistics['user_count'] = form.users.count

    if form.quota.nil? or form.quota == 0
      statistics['pending'] = 0
    else
      statistics['pending'] = form.quota - submissions.where('status != ?', 'new').count
    end

    statistics['total_filled'] = form.submissions.where('status != ?', 'new').count
    statistics['total'] = form.submissions.count

    statistics['form'] = {:id => form.id, :name => form.name}

    expose statistics
  end

  def user
    user = User.find(params[:user_id])

    if user.role == 'agent'
      submissions = user.submissions
    elsif user.role == 'mod'
      submissions = Submission.joins(:assignment).where(assignments: {mod_id: user.id}).distinct(:submission)
    else
      raise "Não é possível ver estatísticas de usuário com permissões de API"
    end

    unless params[:form_id].nil?
      submissions = submissions.where(:form_id => params[:form_id])
    end

    statistics = Hash[Submission::STATUS.map do |status|
      [status, submissions.where(:status => status).count] unless status == 'new'
    end]

    statistics['total_filled'] = submissions.where('status != ?', 'new').count
    statistics['total'] = submissions.count

    assignments_with_quota = user.assignment.where('quota IS NOT NULL AND quota > 0')

    if params[:form_id].nil?
      statistics['form_count'] = user.forms.count
    else
      assignments_with_quota = assignments_with_quota.where(:form_id => params[:form_id])
      statistics['form'] = {:id => params[:form_id], :name => Form.find(params[:form_id]).name}
    end

    if assignments_with_quota.blank?
      statistics['pending'] = 0
    else
      total_quota = assignments_with_quota.sum('quota')
      total_filled = assignments_with_quota.map { |a| Submission.where(:user_id => user.id, :form_id => a.form_id).where('status != ?', 'new').count }.inject(:+) || 0
      statistics['pending'] = total_quota - total_filled
    end

    statistics['user'] = {:id => user.id, :name => user.name}

    expose statistics
  end
end
