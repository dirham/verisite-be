defmodule VerisiteBeWeb.Router do
  use VerisiteBeWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", VerisiteBeWeb do
    pipe_through(:api)

    get("/health", HealthController, :show)
  end
end
