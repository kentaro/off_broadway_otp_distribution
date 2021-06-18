defmodule ExamplesClient do
  use GenServer
  require Logger

  @receiver_name :off_broadway_otp_distribution_receiver

  @impl GenServer
  def init(_opts \\ []) do
    unless Node.connect(:server@localhost) do
      raise "Could not connect to the server"
    end

    receiver = retrieve_receiver_pid()

    Logger.debug(inspect(receiver))
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
  def handle_cast(:request_message, state) do
    Logger.info("got: :request_message")
    push_message(state)
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    Logger.info("terminating...")
    GenServer.call(state.receiver, :unregister)
  end

  defp push_message(state) do
    GenServer.cast(state.receiver, {:push_message, "Hi!"})
  end

  defp retrieve_receiver_pid do
    broadway = :global.whereis_name(@receiver_name)
    if broadway == :undefined do
      Process.sleep(500)
      retrieve_receiver_pid()
    else
      broadway
    end
  end
end
