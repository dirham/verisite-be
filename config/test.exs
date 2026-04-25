import Config

config :verisite_be, VerisiteBe.Repo,
  username: System.get_env("DB_USER", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  database: System.get_env("DB_NAME", "verisite_be_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :verisite_be, VerisiteBeWeb.Endpoint,
  server: false,
  secret_key_base: "test-secret-key-base-change-me"

config :logger, level: :warning
