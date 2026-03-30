import Config

config :verisite_be, VerisiteBe.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "verisite_be_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :verisite_be, VerisiteBeWeb.Endpoint,
  server: false,
  secret_key_base: "test-secret-key-base-change-me"

config :logger, level: :warning
