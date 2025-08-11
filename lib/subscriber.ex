defmodule LiveDataFeed.Subscriber do
  @moduledoc """
  Provides functions to subscribe to stock symbol updates.
  """

  @spec subscribe(atom) :: :ok
  def subscribe(symbol) do
    # The calling process subscribes itself. The registry is `:duplicate`, so this is safe to call multiple times.
    Registry.register(LiveDataFeed.SubscriptionRegistry, symbol, [])
    maybe_start_ticker(symbol)
    :ok
  end

  defp maybe_start_ticker(symbol) do
    # Check if a ticker for this symbol is already running by looking in the TickerRegistry.
    case Registry.lookup(LiveDataFeed.TickerRegistry, symbol) do
      [] ->
        # No ticker found, so we start one using the DynamicSupervisor.
        IO.puts("[System] No ticker for #{symbol} found. Starting one...")
        spec = {LiveDataFeed.Ticker, symbol}
        DynamicSupervisor.start_child(LiveDataFeed.TickerSupervisor, spec)

      _ ->
        # Ticker already running.
        :ok
    end
  end
end
