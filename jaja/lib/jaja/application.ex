defmodule Jaja.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JajaWeb.Telemetry,
      Jaja.Repo,
      {DNSCluster, query: Application.get_env(:jaja, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Jaja.PubSub},
      # Start a worker by calling: Jaja.Worker.start_link(arg)
      # {Jaja.Worker, arg},
      # Start to serve requests, typically the last entry
      JajaWeb.Endpoint,
      JajaWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jaja.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JajaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
