import Config

config :verisite_be,
  ecto_repos: [VerisiteBe.Repo]

config :verisite_be, VerisiteBeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: VerisiteBeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: VerisiteBe.PubSub,
  live_view: [signing_salt: "change-me"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
