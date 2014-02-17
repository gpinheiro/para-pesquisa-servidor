class Correction < ActiveRecord::Base
  belongs_to :submission
  belongs_to :field
  belongs_to :user

  def active_model_serializer
    CorrectionSerializer
  end

  after_validation do
    raise 'O Campo informado não pertence a este formulário' unless self.submission.form.fields.include? self.field
  end
end
