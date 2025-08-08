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
    # Register this client process in the SubscriptionRegistry.
    case Registry.register(LiveDataFeed.SubscriptionRegistry, symbol, []) do
      {:ok, _pid} ->
        IO.puts("[Client #{inspect(state.id)}] Subscribed to #{symbol}")
        # If this is the first time anyone subscribed to this symbol,
        # start a new Ticker process for it under the supervisor.
        maybe_start_ticker(symbol)

        new_state = %{state | subscriptions: MapSet.put(state.subscriptions, symbol)}
        {:noreply, new_state}

      {:error, {:already_registered, _pid}} ->
        IO.puts("[Client #{inspect(state.id)}] Already subscribed to #{symbol}")
        {:noreply, state}
    end
  end

  # This handles the broadcast messages from the Ticker.
  @impl true
  def handle_info({:stock_update, symbol, price}, state) do
    IO.puts("[Client #{inspect(state.id)}] UPDATE for #{symbol}: $#{price}")
    {:noreply, state}
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
