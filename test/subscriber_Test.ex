defmodule LiveDataFeed.SubscriberTest do
  use ExUnit.Case, async: true

  setup do
    # Start the application's supervision tree, which includes the registries.
    LiveDataFeed.Application.start(:test, [])
    :ok
  end

  test "any process can subscribe to a stock symbol" do
    symbol = :AAPL
    test_process = self()

    # Subscribe the current process (the test process) to the symbol.
    assert :ok = LiveDataFeed.Subscriber.subscribe(symbol)

    # Check that the test process is registered as a subscriber.
    assert [{^test_process, []}] = Registry.lookup(LiveDataFeed.SubscriptionRegistry, symbol)

    # Check that a ticker has been started for the symbol.
    assert [{_ticker_pid, _}] = Registry.lookup(LiveDataFeed.TickerRegistry, symbol)
  end

  test "a subscribed process receives stock updates" do
    symbol = :GOOG

    # Subscribe the test process.
    LiveDataFeed.Subscriber.subscribe(symbol)

    # The test process will now wait for a stock update message.
    # Wait up to 5 seconds
    assert_receive {:stock_update, ^symbol, price}, 5000
    assert is_float(price)
  end
end
