defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer
  require Logger
  alias Broadway.Message

  @default_receiver_name :off_broadway_otp_distribution_receiver

  @impl GenServer
  def init(opts \\ []) do
    unless producer = opts[:producer] do
      raise "opts[:producer] must be specified"
    end

    name = opts[:name] || @default_receiver_name
    :global.register_name(name, self())

    {:ok,
     %{
       producer: producer,
       name: name,
       clients: []
     }}
  end

  @impl GenServer
  def handle_call(:register, client, state) do
    clients = [client | state.clients]
    Logger.info("registered: #{inspect(client)}")

    {:reply, :ok, %{state | clients: clients}}
  end

  @impl GenServer
  def handle_call(:unregister, client, state) do
    {client_pid, _} = client

    clients =
      state.clients
      |> Enum.all?(fn {pid, _} ->
        pid != client_pid
      end)

    Logger.info("unregistered: #{inspect(client)}")

    {:reply, :ok, %{state | clients: clients}}
  end

  @impl GenServer
  def handle_call(:request_demand, may_be_producer, state) do
    {pid, _} = may_be_producer

    if pid == state.producer do
      state.clients
      |> Enum.each(fn {pid, _} = client ->
        GenServer.cast(pid, :request_message)
        Logger.info("requested: #{inspect(client)}")
      end)
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:push_message, message}, state) do
    Logger.info("received: #{inspect(message)}")

    messages = transform_messages([message])
    send(state.producer, {:receive_messages, messages})

    {:noreply, state}
  end

  defp transform_messages(messages) do
    messages
    |> Enum.map(fn message ->
      %Message{
        data: message,
        acknowledger: {Broadway.NoopAcknowledger, nil, nil}
      }
    end)
  end

  # Helper APIs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
