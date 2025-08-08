defmodule LiveDataFeed.Ticker do
  @moduledoc """
  A GenServer that simulates a stream of stock price updates for a given symbol.
  It periodically generates a new price and broadcasts it to all subscribers.
  """
  use GenServer

  # --- Client API ---

  @spec start_link(stock_symbol :: atom()) :: GenServer.on_start()
  def start_link(stock_symbol) do
    # We register this GenServer uniquely in the TickerRegistry using its symbol.
    GenServer.start_link(__MODULE__, stock_symbol,
      name: {:via, Registry, {LiveDataFeed.TickerRegistry, stock_symbol}}
    )
  end

  # --- Server Callbacks ---

  @impl true
  def init(stock_symbol) do
    # Initial state: the stock symbol and a starting price.
    state = %{
      symbol: stock_symbol,
      price: :rand.uniform(500) + 50.5
    }

    # Schedule the first price update tick immediately.
    send(self(), :tick)

    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    # Generate a random price change.
    change_percent = (:rand.uniform(100) - 50) / 1000.0
    new_price = (state.price * (1 + change_percent)) |> Float.round(2)

    updated_state = %{state | price: new_price}

    # Broadcast the update to all processes in the SubscriptionRegistry.
    Registry.dispatch(LiveDataFeed.SubscriptionRegistry, state.symbol, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:stock_update, state.symbol, new_price})
    end)

    # Schedule the next tick after a random interval (e.g., 1-5 seconds).
    :timer.send_after(:rand.uniform(4000) + 1000, :tick)

    {:noreply, updated_state}
  end
end
