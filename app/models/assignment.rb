class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :form
  has_many :submissions, dependent: :destroy
  belongs_to :moderator, class_name: 'User', foreign_key: 'mod_id'

  validates_presence_of :user_id
  validates_presence_of :form_id

  before_validation do
    if quota_changed?
      #current_used_quota = Assignment.where(:form => self.form).sum(:quota) - quota_was
      #raise "O limite de quota (#{self.form.quota}) seria excedido para esse formulário." if (current_used_quota + self.quota) > self.form.quota
    end
  end
end
