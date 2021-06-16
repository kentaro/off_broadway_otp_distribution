defmodule OffBroadwayOtpDistribution.Producer do
  use GenStage
  require Logger

  alias Broadway.Producer
  @behaviour Producer

  @impl Producer
  def prepare_for_start(_module, broadway_options) do
    children = [
      {DynamicSupervisor,
       strategy: :one_for_one, name: OffBroadwayOtpDistribution.DynamicSupervisor}
    ]

    {children, broadway_options}
  end

  @impl GenStage
  def init(opts) do
    {:ok, receiver} =
      DynamicSupervisor.start_child(
        OffBroadwayOtpDistribution.DynamicSupervisor,
        {
          OffBroadwayOtpDistribution.Receiver,
          opts[:receiver] ++ [producer: self()]
        }
      )

    {:producer,
     %{
       demand: 0,
       receiver: receiver
     }}
  end

  @impl GenStage
  def handle_demand(incoming_demand, %{demand: demand} = state) do
    request_message(state)
    {:noreply, [], %{state | demand: demand + incoming_demand}}
  end

  @impl GenStage
  def handle_info({:receive_messages, messages}, state) do
    if state.demand > 0 do
      {:noreply, messages, %{state | demand: state.demand - 1}}
    else
      # ignore message if demand is 0
      {:noreply, [], state}
    end
  end

  defp request_message(state) do
    GenServer.call(state.receiver, :request)
  end
end
