defmodule VerisiteBeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :verisite_be

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(Plug.Session,
    store: :cookie,
    key: "_verisite_be_key",
    signing_salt: "change-me"
  )

  plug(VerisiteBeWeb.Router)
end
