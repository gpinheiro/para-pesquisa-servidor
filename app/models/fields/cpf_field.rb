class CpfField < Field
  requirable

  def get_mod_11(step_total)
    digit_reminder = step_total % 11

    if digit_reminder < 2
      0
    else
      (11 - digit_reminder).round
    end
  end

  def custom_validation(cpf)
    begin
      cpf_parts = cpf.gsub(/[^\d]/, '')
      cpf_verifier = cpf_parts[-2..-1]
      cpf_digits = cpf_parts[0..8]

      first_step_total = 0
      2.upto 10 do |num|
        first_step_total += Float(cpf_digits[(num * -1) + 1]) * num
      end

      first_digit = get_mod_11 first_step_total

      second_step_total = 0
      cpf_digits += first_digit.to_s
      2.upto 11 do |num|
        second_step_total += Float(cpf_digits[(num * -1) + 1]) * num
      end

      second_digit = get_mod_11 second_step_total
    rescue
      raise "#{cpf} não é um CPF válido" unless cpf_verifier == (first_digit.to_s + second_digit.to_s)
    end

    true
  end
end