class Field < ActiveRecord::Base
  belongs_to :section

  serialize :validations, Hash
  serialize :actions, Array

  validates_presence_of :label
  validates_inclusion_of :type, in: %w(TextField CpfField LabelField EmailField DinheiroField DatetimeField CheckboxField PrivateField RadioField SelectField UrlField OrderedlistField NumberField)
  validates_inclusion_of :layout, in: %w(small medium big single_column multiple_columns), allow_nil: true

  scope :same_section, -> (section_id) { where(section_id: section_id) }

  before_save :validate_identifier_uniqueness

  def validate_identifier_uniqueness
    if self.identifier? and not self.section.nil?
      self.section.form.fields.where(:identifier => true).update_all(:identifier => false)
    end
  end

  def active_model_serializer
    FieldSerializer
  end

  def validate_answer!(answer)
    self.validations.each do |validation, params|
      __send__ ('validate_' + validation.to_s).to_sym, answer, params
    end

    __send__(:custom_validation, answer) if self.respond_to? :custom_validation
  end

  def sid
    ('f' + self.id.to_s).to_sym
  end

  private

  def self.ranged
    define_method 'range=' do |range|
      if range.empty?
        self.validations.delete :range
      else
        self.validations[:range] = Range.new range.min, range.max
      end
    end
  end

  def validate_range(value, range)
    value = value.length if value.kind_of? String
    raise "O valor dado a '#{self.label}' não está entre '#{range}'" unless range.include? value
    true
  end

  def self.requirable
    define_method 'required=' do |required|
      unless required
        self.validations.delete :required
        return
      end

      self.validations[:required] = required
    end
  end

  def validate_required(value, required)
    raise "O campo '#{self.label}' é obrigatório" if required and (value.nil? or value.blank?)
  end

  def self.has_options(&options)
    has_many :choices, :foreign_key => 'field_id'

    after_save do
      unless @_options.nil?
        self.choices.clear

        @_options.each do |option_params|
          self.choices.create! option_params
        end
      end

    end

    define_method 'options=' do |options|
      @_options = options
    end

    define_method 'options' do
      self.choices
    end

    define_method 'custom_validation' do |options|
      raise "Opções precisam ser encapsuladas em um array. Recebido: '#{options}'" unless options.is_a? Array

      has_other_option = !self.choices.find_by_value('other').nil?
      other_option_used = false

      options.each do |option|
        unless self.choices.find_by_value(option)
          if has_other_option and not other_option_used
            other_option_used = true
          else
            #raise "Opção '#{option}' inválida para o campo #{self.label}"
          end
        end
      end
    end
  end

end

