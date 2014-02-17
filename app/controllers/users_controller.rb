class UsersController < ApplicationController
  load_and_authorize_resource

  caches :show, :forms, :users

  def index
    user_list = User.active

    if params[:name_like]
      user_list = user_list.where('lower(name) like ?', "%#{params[:name_like].downcase}%")
    end

    if params[:username_like]
      user_list = user_list.where('lower(username) like ?', "%#{params[:username_like].downcase}%")
    end

    if params[:by_role]
      roles = params[:by_role].include?(',') ? params[:by_role].split(',') : [params[:by_role]]
      user_list = user_list.where(:role => roles)
    end

    user_list = user_list.paginate(:page => params[:page]) if params[:as].nil? or params[:as] == 'paginated_collection'

    expose user_list
  end

  def show
    user = User.find params[:id]
    expose user, except: [:password_digest, :updated_at]
  end

  def create
    fields = user_params
    fields[:password_confirmation] = fields[:password] if fields[:password_confirmation].nil?
    user = User.create! fields
    head :created
    expose :user_id => user.id
  end

  def update
    user = User.find(params[:id])

    unless params[:password].nil?
      params[:password_confirmation] = params[:password]
    end

    unless params[:avatar].nil?
      user.avatar = params[:avatar]
    end

    user.update(user_params)
    head :no_content
  end

  def destroy
    User.find(params[:id]).update!(active: false)
    head :no_content
  end

  def save_avatar
    user = User.find(params[:id])
    user.avatar = params[:avatar]
    user.save!
    expose :avatar => user.avatar.url
  end

  def remove_avatar
    user = User.find(params[:id])
    user.avatar = nil
    user.save!
    head :no_content
  end

  def forms
    user = User.find(params[:user_id])

    case user.role
      when 'agent' then
        expose_stashed :forms, user.assignment, except: [:form_id, :moderator, :user]
      when 'mod' then
        used_form_ids = []
        result = []
        Assignment.where(:mod_id => user.id).each do |a|
          unless used_form_ids.include?(a.form_id)
            result.push(a)
            used_form_ids.push(a.form_id)
          end
        end

        expose_stashed :forms, result, except: [:moderator, :user, :form_id, :quota]
      else
        head :bad_request
    end
  end

  def users
    user = User.find(params[:id])

    expose Assignment.joins(:user).where(:mod_id => user.id), except: [:moderator, :form]
  end

  def submissions
    user = User.find(params[:user_id])

    case user.role
      when 'agent' then
        submissions = user.submissions.with_dependencies
      when 'mod' then
        submissions = Submission.with_dependencies.joins(:assignment).where(assignments: {mod_id: user.id}).distinct(:submission)
      else
        head :bad_request
        return
    end

    submissions = datetime_filters(submissions, nil, 'submissions')

    unless params[:by_status].nil?
      submissions = submissions.where(:status => params[:by_status])
    end

    unless params[:form_id].nil?
      submissions = submissions.where(:form_id => params[:form_id])
    end

    submissions = submissions.paginate(:page => params[:page]) if params[:as] == 'paginated_collection'

    expose_stashed :submissions, submissions
  end

  private
  def user_params
    params.permit :name, :username, :email, :password, :password_confirmation, :role
  end
end

