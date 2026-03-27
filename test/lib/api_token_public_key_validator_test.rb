require "test_helper"

class ApiTokenPublicKeyValidatorTest < ActiveSupport::TestCase
  def test_valid_2048_rsa_public_key
    key = OpenSSL::PKey::RSA.new(2048)
    validator = ApiTokenPublicKeyValidator.new(key.public_key.to_pem)
    assert validator.valid?
    assert_nil validator.error_message
    assert_equal key.public_key.to_pem.strip, validator.sanitized_key
  end

  def test_rejects_private_key
    key = OpenSSL::PKey::RSA.new(2048)
    validator = ApiTokenPublicKeyValidator.new(key.to_pem)
    assert_not validator.valid?
    assert_equal "Vložte verejný RSA kľúč, nie súkromný.", validator.error_message
  end

  def test_rejects_invalid_key_format
    validator = ApiTokenPublicKeyValidator.new("not a valid key")
    assert_not validator.valid?
    assert_equal "Neplatný RSA kľúč. Uistite sa, že vstup obsahuje PEM formát verejného kľúča.", validator.error_message
  end

  def test_rejects_512_bit_key
    key = OpenSSL::PKey::RSA.new(512)
    validator = ApiTokenPublicKeyValidator.new(key.public_key.to_pem)
    assert_not validator.valid?
    assert_equal "Kľúč musí mať 2048 bitov. Aktuálny kľúč má 512 bitov.", validator.error_message
  end

  def test_rejects_4096_bit_key
    key = OpenSSL::PKey::RSA.new(4096)
    validator = ApiTokenPublicKeyValidator.new(key.public_key.to_pem)
    assert_not validator.valid?
    assert_equal "Kľúč musí mať 2048 bitov. Aktuálny kľúč má 4096 bitov.", validator.error_message
  end

  def test_handles_blank_input
    validator = ApiTokenPublicKeyValidator.new("")
    assert validator.valid?
    assert_nil validator.sanitized_key
  end

  def test_handles_whitespace_only
    validator = ApiTokenPublicKeyValidator.new("   \n\t  ")
    assert validator.valid?
    assert_nil validator.sanitized_key
  end

  def test_strips_whitespace_from_valid_key
    key = OpenSSL::PKey::RSA.new(2048)
    validator = ApiTokenPublicKeyValidator.new("\n  #{key.public_key.to_pem}\n  ")
    assert validator.valid?
    assert_equal key.public_key.to_pem.strip, validator.sanitized_key
  end
end
