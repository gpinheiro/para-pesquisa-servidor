class Log < ActiveRecord::Base
  belongs_to :submission
  belongs_to :user
  belongs_to :stop_reason

  validates_inclusion_of :action, :in => %w(created started submitted reset revised approved reproved canceled rescheduled transferred)

  default_scope -> { includes(:stop_reason) }

  before_save do
    if self.date.nil?
      self.date = DateTime.now
    end
  end
end
