defmodule VerisiteBe.Auth.Password do
  @moduledoc false

  @iterations 210_000
  @salt_bytes 16

  def hash(password) when is_binary(password) do
    salt = :crypto.strong_rand_bytes(@salt_bytes)
    digest = digest(password, salt)

    "pbkdf2_sha256$#{@iterations}$#{Base.encode64(salt)}$#{Base.encode64(digest)}"
  end

  def verify(password, "pbkdf2_sha256$" <> rest) when is_binary(password) do
    with [iterations, salt, digest] <- String.split(rest, "$"),
         {iterations, ""} <- Integer.parse(iterations),
         {:ok, salt} <- Base.decode64(salt),
         {:ok, expected_digest} <- Base.decode64(digest) do
      actual_digest = digest(password, salt, iterations)
      Plug.Crypto.secure_compare(actual_digest, expected_digest)
    else
      _ -> false
    end
  end

  def verify(_password, _hash), do: false

  defp digest(password, salt, iterations \\ @iterations) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, iterations, 32)
  end
end
