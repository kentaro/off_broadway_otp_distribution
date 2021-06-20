defmodule ExamplesClient do
  use GenServer
  require Logger

  @server_name :server@localhost
  @receiver_name :off_broadway_otp_distribution_receiver

  @impl GenServer
  def init(_opts \\ []) do
    unless Node.connect(@server_name) do
      raise "Could not connect to the server"
    end

    :global.sync()
    receiver = :global.whereis_name(@receiver_name)
    GenServer.call(receiver, :register)

    {:ok,
     %{
       receiver: receiver
     }}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def handle_cast({:push_message, message}, state) do
    GenServer.cast(state.receiver, {:push_message, message})
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:request_message, state) do
    Logger.info("request_message")
    GenServer.cast(state.receiver, {:respond_to_pull_request, "I'm alive!"})
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    Logger.info("terminating...")
    GenServer.call(state.receiver, :unregister)
  end
end
