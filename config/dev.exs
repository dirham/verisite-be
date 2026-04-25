import Config

config :verisite_be, VerisiteBe.Repo,
  username: System.get_env("DB_USER", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  database: System.get_env("DB_NAME", "verisite_be"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :verisite_be, VerisiteBeWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT", "4000"))
  ],
  code_reloader: true,
  debug_errors: true,
  check_origin: false,
  secret_key_base: "dev-secret-key-base-change-me",
  watchers: []

config :phoenix, :plug_init_mode, :runtime
