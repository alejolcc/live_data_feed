defmodule LiveDataFeed.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, name: LiveDataFeed.SubscriptionRegistry, keys: :duplicate},
      {Registry, name: LiveDataFeed.TickerRegistry, keys: :unique},
      {DynamicSupervisor, name: LiveDataFeed.TickerSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: LiveDataFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
