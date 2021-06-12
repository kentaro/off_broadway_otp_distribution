defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer
  require Logger

  @impl GenServer
  def init(state) do
    :global.register_name(:off_broadway_otp_distribution_receiver, self())
    {:ok, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.info("received: #{inspect(msg)}")
    OffBroadwayOtpDistribution.Queue.enqueue(msg)
    {:noreply, state}
  end

  # Helper APIs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
