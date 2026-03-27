class ApiTokenPublicKeyValidator
  EXPECTED_BITS = 2048

  def initialize(public_key_string)
    @public_key_string = public_key_string&.strip
    @error = nil
  end

  def valid?
    validate
    @error.nil?
  end

  def error_message
    @error
  end

  def sanitized_key
    validate
    @error.nil? ? @public_key_string : nil
  end

  private

  def validate
    return if @error

    begin
      key = OpenSSL::PKey::RSA.new(@public_key_string)
    rescue OpenSSL::PKey::RSAError
      @error = "Neplatný RSA kľúč. Uistite sa, že vstup obsahuje PEM formát verejného kľúča."
      return
    end

    if key.private?
      @error = "Vložte verejný RSA kľúč, nie súkromný."
      return
    end

    return unless key.n.num_bits != EXPECTED_BITS

    @error = "Kľúč musí mať #{EXPECTED_BITS} bitov. Aktuálny kľúč má #{key.n.num_bits} bitov."
    nil
  end
end
