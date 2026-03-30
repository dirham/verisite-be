import Config

config :verisite_be, VerisiteBe.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "verisite_be",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :verisite_be, VerisiteBeWeb.Endpoint,
  code_reloader: true,
  debug_errors: true,
  check_origin: false,
  secret_key_base: "dev-secret-key-base-change-me",
  watchers: []

config :phoenix, :plug_init_mode, :runtime
