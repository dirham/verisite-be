defmodule VerisiteBe.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VerisiteBe.Repo,
      {Phoenix.PubSub, name: VerisiteBe.PubSub},
      VerisiteBeWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: VerisiteBe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    VerisiteBeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
