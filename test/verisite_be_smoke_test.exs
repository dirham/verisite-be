defmodule VerisiteBeSmokeTest do
  use ExUnit.Case, async: true

  test "documents the application root module" do
    assert VerisiteBe.module_info(:module) == VerisiteBe
  end
end
