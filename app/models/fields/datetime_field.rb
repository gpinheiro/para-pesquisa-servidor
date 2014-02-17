class DatetimeField < Field
  requirable
  #TODO: Add range support

  def custom_validation(answer)
    raise "Data '#{answer}' é inválida" if Time.parse(answer).nil?
  end
end