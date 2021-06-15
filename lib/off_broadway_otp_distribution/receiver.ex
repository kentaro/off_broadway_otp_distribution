defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer
  require Logger
  alias Broadway.Message

  @default_receiver_name :off_broadway_otp_distribution_receiver

  @impl GenServer
  def init(opts \\ []) do
    name = opts[:name] || @default_receiver_name
    :global.register_name(name, self())
    {:ok, %{opts: opts}}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("received: #{inspect(message)}")
    messages = transform_messages([message])
    send(state.opts[:producer], {:receive_messages, messages})
    {:noreply, state}
  end

  defp transform_messages(messages) do
    messages
    |> Enum.map(fn message ->
      %Message{
        data: message,
        acknowledger: {Broadway.NoopAcknowledger, nil, nil},
      }
    end)
  end

  # Helper APIs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
