defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer
  require Logger

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
    send(state.opts[:producer], {:receive_messages, [message]})
    {:noreply, state}
  end

  # Helper APIs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
