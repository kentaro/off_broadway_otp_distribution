defmodule OffBroadwayOtpDistribution.Receiver do
  use GenServer

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  # Helper APIs

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
end
