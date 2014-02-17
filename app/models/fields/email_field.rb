class EmailField < Field
  ranged
  requirable

  def custom_validation(answer)
    raise "E-mail #{answer} não é válido" if /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/.match(answer).nil?
  end
end