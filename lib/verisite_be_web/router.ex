defmodule VerisiteBeWeb.Router do
  use VerisiteBeWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated_api do
    plug(:accepts, ["json"])
    plug(VerisiteBeWeb.Plugs.AuthenticateBearer)
  end

  scope "/api", VerisiteBeWeb do
    pipe_through(:api)

    get("/health", HealthController, :show)
    post("/auth/login", AuthController, :login)
  end

  scope "/api", VerisiteBeWeb do
    pipe_through(:authenticated_api)

    get("/profile", ProfileController, :show)
    patch("/profile", ProfileController, :update)
    post("/profile/photo", ProfileController, :update_photo)
    put("/profile/language", ProfileController, :update_language)
    post("/profile/logout", ProfileController, :logout)
    post("/attendance/clock-in", AttendanceController, :clock_in)
  end
end
