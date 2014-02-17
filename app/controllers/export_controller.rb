require 'csv'

class ExportController < ApplicationController
  include ActionController::DataStreaming

  skip_authorization_check :only => [:progress, :exports]

  @@background_job = nil

  def exports
    job_id = Rails.cache.read('export_job_running')

    last_exports = {}
    %w(answers users forms fields submissions).each do |export|
      key = 'last_' + export + '_export'
      cached = Rails.cache.read(key)
      if cached.nil?
        last_exports[key] = nil
      else
        last_exports[key] = {:date => cached[:date].iso8601, :url => cached[:url], :job_id => cached[:job_id]}
      end
    end

    expose ({:running_job_id => job_id}).merge(last_exports)
  end

  def users
    authorize! :export_csv, User

    success, job_id = background do
      users = User.active

      if params[:by_role]
        roles = params[:by_role].include?(',') ? params[:by_role].split(',') : [params[:by_role]]
        users = users.where(:role => roles)
      end

      translated_role = {'mod' => 'Coordenador', 'agent' => 'Pesquisador', 'api' => 'Administrador'}

      total_users = users.count
      processed_users = 0

      csv = CSV.generate do |csv|
        if params[:include_header] == true
          csv << ['user_id', 'Nome', 'Nome de usuário', 'E-mail', 'Data de cadastro', 'Cargo']
        end

        users.each do |user|
          csv << [user.id, user.name, user.username, user.email, user.created_at, translated_role[user.role]]

          processed_users += 1
          Rails.cache.write(job_id, total: total_users, current: processed_users, complete: false, url: nil)
        end
      end

      uploader = CsvUploader.new
      uploader.store!(CSVStringIO.new('users_' + Time.now.to_i.to_s + '.csv', csv))

      raise 'Não foi possível fazer o upload do arquivo no momento. Tente novamente mais tarde' if uploader.file.nil?

      Rails.cache.write(job_id, :url => uploader.file.url, :complete => true, :total => total_users, :current => processed_users)
      Rails.cache.write('last_users_export', {:date => Time.now, :url => uploader.file.url, :job_id => job_id})
    end

    if success
      Rails.cache.write(job_id, total: 0, current: 0, complete: false, url: nil)
      expose :job_id => job_id
    else
      raise 'Uma exportação já está em progresso.'
    end
  end

  def forms
    authorize! :export_csv, Form

    success, job_id = background do
      forms = Form.all

      total_forms = forms.count
      processed_forms = 0

      csv = CSV.generate do |csv|
        if params[:include_header] == true
          csv << ['form_id', 'Título', 'Subtítulo', 'Data de criação']
        end

        forms.each do |form|
          csv << [form.id, form.name, form.subtitle, form.created_at]

          processed_forms += 1
          Rails.cache.write(job_id, total: total_forms, current: processed_forms, complete: false, url: nil)
        end
      end

      uploader = CsvUploader.new
      uploader.store!(CSVStringIO.new('forms_' + Time.now.to_i.to_s + '.csv', csv))

      raise 'Não foi possível fazer o upload do arquivo no momento. Tente novamente mais tarde' if uploader.file.nil?

      Rails.cache.write(job_id, :url => uploader.file.url, :complete => true, :total => total_forms, :current => processed_forms)
      Rails.cache.write('last_forms_export', {:date => Time.now, :url => uploader.file.url, :job_id => job_id})
    end

    if success
      Rails.cache.write(job_id, total: 0, current: 0, complete: false, url: nil)
      expose :job_id => job_id
    else
      raise 'Uma exportação já está em progresso.'
    end
  end

  def submissions
    authorize! :export_csv, Submission

    success, job_id = background do
      submissions = Submission.with_dependencies.includes(:form)
      submissions = datetime_filters(submissions)

      if params[:by_status]
        submissions = submissions.where(status: params[:by_status])
      end

      form = Form.includes(:fields).find(params[:form_id])

      total_submissions = submissions.count
      processed_submissions = 0

      csv = CSV.generate do |csv|
        if params[:include_header] == true
          fixed_fields = ['submission_id', 'form_id', 'user_id']

          # If this form uses imported submissions we add the readonly fields to the header
          if form.allow_new_submissions == false
            readonly_fields = form.fields.where(read_only: true)
            readonly_fields.each { |field| fixed_fields.append(field.label) } unless readonly_fields.nil?
          end

          fixed_fields += ['Data de criação', 'Data de preenchimento', 'Data de aprovação']

          csv << fixed_fields
        end

        submissions.each do |submission|
          row = [submission.id, submission.form.id, submission.user.id]

          if form.allow_new_submissions == false
            row += readonly_fields.map { |readonly_field| submission.answers[readonly_field.id] } unless readonly_fields.nil?
          end


          row += [submission.last_created_date,
                  submission.last_started_date,
                  submission.last_approved_date]

          csv << row

          processed_submissions += 1
          Rails.cache.write(job_id, total: total_submissions, current: processed_submissions, complete: false, url: nil)
        end
      end

      uploader = CsvUploader.new
      uploader.store!(CSVStringIO.new('submissions_' + Time.now.to_i.to_s + '.csv', csv))

      raise 'Não foi possível fazer o upload do arquivo no momento. Tente novamente mais tarde' if uploader.file.nil?

      Rails.cache.write(job_id, :url => uploader.file.url, :complete => true, :total => total_submissions, :current => processed_submissions)
      Rails.cache.write('last_submissions_export', {:date => Time.now, :url => uploader.file.url, :job_id => job_id})
    end

    if success
      Rails.cache.write(job_id, total: 0, current: 0, complete: false, url: nil)
      expose :job_id => job_id
    else
      raise 'Uma exportação já está em progresso.'
    end
  end

  def fields
    authorize! :export_csv, Field

    success, job_id = background do
      fields = Field.where(read_only: false).joins(:section)

      total_fields = fields.count
      processed_fields = 0

      csv = CSV.generate do |csv|
        if params[:include_header] == true
          csv << ['field_id', 'form_id', 'Título', 'Tipo']
        end

        fields.each do |field|
          next if field.section.nil?

          csv << [field.id, field.section.form_id, field.label, field.type]

          processed_fields += 1
          Rails.cache.write(job_id, total: total_fields, current: processed_fields, complete: false, url: nil)
        end
      end

      uploader = CsvUploader.new
      uploader.store!(CSVStringIO.new('fields_' + Time.now.to_i.to_s + '.csv', csv))

      raise 'Não foi possível fazer o upload do arquivo no momento. Tente novamente mais tarde' if uploader.file.nil?

      Rails.cache.write(job_id, :url => uploader.file.url, :complete => true, :total => total_fields, :current => processed_fields)
      Rails.cache.write('last_fields_export', {:date => Time.now, :url => uploader.file.url, :job_id => job_id})
    end

    if success
      Rails.cache.write(job_id, total: 0, current: 0, complete: false, url: nil)
      expose :job_id => job_id
    else
      raise 'Uma exportação já está em progresso.'
    end
  end

  def answers
    authorize! :export_csv, Submission

    success, job_id = background do
      submissions = Submission.where(form_id: params[:form_id]).select(:id, :answers)
      submissions = datetime_filters(submissions)

      if params[:by_status]
        submissions = submissions.where(status: params[:by_status])
      end

      total_submissions = submissions.count
      processed_submissions = 0

      csv = CSV.generate do |csv|
        if params[:include_header] == true
          csv << ['submission_id', 'field_id', 'Resposta', 'Ordem']
        end

        submissions.each do |submission|
          submission.answers.each do |field_id, answers|
            answers = [answers] unless answers.kind_of?(Array)

            order = 0

            answers.each do |answer|
              order += 1
              csv << [submission.id, field_id, answer, order]
            end
          end

          processed_submissions += 1
          Rails.cache.write(job_id, total: total_submissions, current: processed_submissions, complete: false, url: nil)
        end
      end

      uploader = CsvUploader.new
      uploader.store!(CSVStringIO.new('answers_' + Time.now.to_i.to_s + '.csv', csv))

      raise 'Não foi possível fazer o upload do arquivo no momento. Tente novamente mais tarde' if uploader.file.nil?

      Rails.cache.write(job_id, :url => uploader.file.url, :complete => true, :total => total_submissions, :current => processed_submissions)
      Rails.cache.write('last_answers_export', {:date => Time.now, :url => uploader.file.url, :job_id => job_id})
    end

    if success
      Rails.cache.write(job_id, total: 0, current: 0, complete: false, url: nil)
      expose :job_id => job_id
    else
      raise 'Uma exportação já está em progresso.'
    end
  end

  def progress
    job_id = params[:job_id] || Rails.cache.read('export_job_running')
    raise 'O ID do Job não pode ser vazio.' if job_id.nil?

    job = Rails.cache.read(job_id)
    raise 'Job não encontrado.' if job.nil?

    expose job
  end

  def background(&block)
    background_job = Rails.cache.read('export_job_running')

    if background_job.nil?
      Thread.new do
        begin
          yield
        rescue => exception
          Raven.capture_exception(exception)
        end
        ActiveRecord::Base.connection.close
        Rails.cache.delete('export_job_running')
      end

      job_id = SecureRandom.hex

      Rails.cache.write('export_job_running', job_id, expires_in: 60.minutes)

      return [true, job_id]
    end

    [false, nil]
  end
end
