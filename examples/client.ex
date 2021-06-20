defmodule ExamplesClient do
  use GenServer
  require Logger

  @server_name :server@localhost
  @receiver_name :off_broadway_otp_distribution_receiver
  @max_retry_count 10

  def start(_type, args) do
    opts = [strategy: :one_for_one, name: ExamplesClient.Supervisor]
    [
      {__MODULE__, args},
    ] |> Supervisor.start_link(opts)
  end

  @impl GenServer
  def init(opts \\ []) do
    connect_to_node(opts[:node_name])
    receiver = connect_to_receiver(@receiver_name, @max_retry_count)

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
  def handle_info({:DOWN, _, _, _, reason}, state) do
    Logger.info("server down (#{reason})}")
    {:noreply, %{state | receiver: nil}}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.info("terminating... (#{inspect(reason)})")
  end

  defp connect_to_node(node_name) do
    unless Node.connect(node_name) do
      raise "Could not connect to the server"
    end
  end

  defp connect_to_receiver(receiver_name, retry_count) do
    receiver = try_connect_to_receiver(receiver_name, retry_count)
    GenServer.call(receiver, :register)
    Process.monitor(receiver)
    receiver
  end

  defp try_connect_to_receiver(receiver_name, retry_count) do
    if retry_count > 0 do
      :global.sync()
      receiver = :global.whereis_name(receiver_name)

      if receiver == :undefined do
        Logger.debug("waiting for receiver is up...")
        Process.sleep(3_000)
        try_connect_to_receiver(receiver_name, retry_count - 1)
      else
        receiver
      end
    else
      raise("couldn't connect to #{receiver_name}")
    end
  end
end
