class Form < ActiveRecord::Base
  include RocketPants::Cacheable
  scope :published, -> { where('(pub_start <= :now AND pub_end >= :now) OR (pub_start IS NULL OR pub_end IS NULL)', {:now => Time.now}) }

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :sections, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :fields, through: :sections
  has_many :stop_reasons, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def active_model_serializer
    FormSerializer
  end

  def quota
    self.assignments.sum('quota')
  end
end