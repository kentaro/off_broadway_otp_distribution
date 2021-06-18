defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer
  require Logger
  alias Broadway.Message

  @default_receiver_name :off_broadway_otp_distribution_receiver

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts \\ []) do
    unless producer = opts[:producer] do
      raise "opts[:producer] must be specified"
    end

    name = opts[:name] || @default_receiver_name
    :global.register_name(name, self())

    {:ok,
     %{
       name: name,
       producer: producer,
       clients: [],
       mode: opts[:mode]
     }}
  end

  @impl GenServer
  def handle_call(:register, client, state) do
    clients = [client | state.clients]
    Logger.info("register: #{inspect(client)}")

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

    Logger.info("unregister: #{inspect(client)}")

    {:reply, :ok, %{state | clients: clients}}
  end

  @impl GenServer
  def handle_call(:pull_messages, may_be_producer, state) do
    Logger.info("pull_messages: #{inspect(may_be_producer)}")

    {pid, _} = may_be_producer

    if pid == state.producer do
      state.clients
      |> Enum.each(fn {pid, _} = client ->
        GenServer.cast(pid, :request_message)
        Logger.info("request_message: #{inspect(client)}")
      end)
    else
      Logger.info("Ignored :pull_messages call not from the producer.")
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:push_message, message}, state) do
    Logger.info("push_message: #{inspect(message)}")

    if state.mode == :push do
      messages = transform_messages([message])
      send(state.producer, {:push_messages, messages})
    else
      Logger.info("Ignored a pushed message because the producer doesn't run in the push mode.")
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:respond_to_pull_request, message}, state) do
    Logger.info("respond_to_pull_request: #{inspect(message)}")

    messages = transform_messages([message])
    send(state.producer, {:respond_to_pull_request, messages})

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
end
