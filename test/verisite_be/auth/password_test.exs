defmodule VerisiteBe.Auth.PasswordTest do
  use ExUnit.Case, async: true

  alias VerisiteBe.Auth.Password

  test "verifies matching password hashes" do
    hash = Password.hash("password123")

    assert Password.verify("password123", hash)
    refute Password.verify("wrong-password", hash)
  end
end
