class NumberField < Field
  ranged
  requirable

  def custom_validation(answer)
    Float(answer) rescue raise "O valor '#{answer}' não é um número"
  end
end