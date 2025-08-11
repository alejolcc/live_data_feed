defmodule LiveDataFeedTest do
  use ExUnit.Case, async: true

  setup do
    client_id = :test_client
    {:ok, client_pid} = LiveDataFeed.Client.start_link(client_id)

    on_exit(fn ->
      Process.exit(client_pid, :kill)
    end)

    {:ok, client: client_pid, client_id: client_id}
  end

  test "client can subscribe to a stock symbol", %{client: client} do
    symbol = :AAPL

    # Subscribe the client to the symbol.
    assert :ok = LiveDataFeed.Client.subscribe(client, symbol)

    # Allow some time for the subscription to be processed and the ticker to be started.
    Process.sleep(100)

    # Check that the client is registered as a subscriber.
    assert [{^client, []}] = Registry.lookup(LiveDataFeed.SubscriptionRegistry, symbol)

    # Check that a ticker has been started for the symbol.
    assert [{_ticker_pid, _}] = Registry.lookup(LiveDataFeed.TickerRegistry, symbol)
  end

  test "client receives stock updates after subscribing" do
    symbol = :GOOG

    LiveDataFeed.Subscriber.subscribe(symbol)

    # Allow some time for the subscription to be processed and the ticker to be started.
    Process.sleep(100)

    # The test process will now wait for a stock update message.
    # Wait up to 5 seconds
    assert_receive {:stock_update, ^symbol, _price}, 5000
  end

  @tag :wip
  test "multiple clients can subscribe to the same stock" do
    symbol = :TSLA

    # Start two clients
    {:ok, client1} = LiveDataFeed.Client.start_link(:client1)

    # Subscribe both clients to the same symbol
    LiveDataFeed.Client.subscribe(client1, symbol)
    LiveDataFeed.Subscriber.subscribe(symbol)

    # Allow some time for the subscription to be processed and the ticker to be started.
    Process.sleep(100)

    assert length(Registry.lookup(LiveDataFeed.SubscriptionRegistry, symbol)) == 2

    # The test process will now wait for a stock update message.
    # Wait up to 5 seconds
    assert_receive {:stock_update, ^symbol, _price}, 5000

    # Check that only one Ticker process is running for this symbol.
    assert length(Registry.lookup(LiveDataFeed.TickerRegistry, symbol)) == 1
  end

  test "ticker starts only once for a symbol", %{client: client} do
    symbol = :AMZN

    # Subscribe to the same symbol twice.
    LiveDataFeed.Client.subscribe(client, symbol)
    LiveDataFeed.Client.subscribe(client, symbol)

    # Allow some time for the subscription to be processed and the ticker to be started.
    Process.sleep(100)

    # Check that only one Ticker process is running for this symbol.
    assert length(Registry.lookup(LiveDataFeed.TickerRegistry, symbol)) == 1
  end
end
