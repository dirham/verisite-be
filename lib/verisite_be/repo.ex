defmodule VerisiteBe.Repo do
  use Ecto.Repo,
    otp_app: :verisite_be,
    adapter: Ecto.Adapters.Postgres
end
