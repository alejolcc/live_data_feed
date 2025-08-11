defmodule LiveDataFeed.Client do
  @moduledoc """
  A GenServer that simulates a client application.
  It can subscribe to stock symbols and will print any updates it receives.
  """
  use GenServer

  # --- Client API ---

  @spec start_link(client_id :: any) :: GenServer.on_start()
  def start_link(client_id) do
    GenServer.start_link(__MODULE__, client_id, name: {:global, {:client, client_id}})
  end

  @spec subscribe(pid | atom, atom | list(atom)) :: :ok
  def subscribe(client, symbols) when is_list(symbols) do
    for symbol <- symbols, do: subscribe(client, symbol)
    :ok
  end

  def subscribe(client, symbol) when is_atom(symbol) do
    GenServer.cast(client, {:subscribe, symbol})
  end

  # --- Server Callbacks ---

  @impl true
  def init(client_id) do
    IO.puts("Client #{inspect(client_id)} started. PID: #{inspect(self())}")
    {:ok, %{id: client_id, subscriptions: MapSet.new()}}
  end

  @impl true
  def handle_cast({:subscribe, symbol}, state) do
    # Use the new Subscriber module to handle the subscription logic for this process.
    LiveDataFeed.Subscriber.subscribe(symbol)
    IO.puts("[Client #{inspect(state.id)}] Subscribed to #{symbol}")
    new_state = %{state | subscriptions: MapSet.put(state.subscriptions, symbol)}
    {:noreply, new_state}
  end

  # This handles the broadcast messages from the Ticker.
  @impl true
  def handle_info({:stock_update, symbol, price}, state) do
    IO.puts("[Client #{inspect(state.id)}] UPDATE for #{symbol}: $#{price}")
    {:noreply, state}
  end
end
