# How to run this simulation

1.  Open an `iex` session with your project loaded:

    ```bash
    iex -S mix
    ```

2.  Start some clients:

    ```elixir
    iex> {:ok, client1_pid} = LiveDataFeed.Client.start_link("Alice")
    iex> {:ok, client2_pid} = LiveDataFeed.Client.start_link("Bob")
    iex> {:ok, client3_pid} = LiveDataFeed.Client.start_link("Charlie")
    ```

3.  Subscribe clients to stock symbols. Notice how the system automatically starts a `Ticker` process the first time a symbol is subscribed to.

    ```elixir
    iex> LiveDataFeed.Client.subscribe(client1_pid, :AAPL)
    iex> LiveDataFeed.Client.subscribe(client2_pid, [:GOOG, :MSFT])
    iex> LiveDataFeed.Client.subscribe(client3_pid, [:AAPL, :MSFT])
    ```

4.  Watch the console. You will see updates flowing to the clients.

5.  Test fault tolerance. Let's find and kill the `Ticker` for `:AAPL`.

    First, find the process ID. We can use `GenServer.whereis/1` because the `TickerRegistry` uses unique keys.

    ```elixir
    iex> aapl_ticker_pid = GenServer.whereis({:via, Registry, {LiveDataFeed.TickerRegistry, :AAPL}})
    ```

    Now, kill the process:

    ```elixir
    iex> Process.exit(aapl_ticker_pid, :kill)
    ```

    The `TickerSupervisor` will immediately restart it, and the clients will continue to receive updates for `:AAPL` without any interruption.