defmodule OffBroadwayOtpDistribution.Producer do
  use GenStage
  alias Broadway.Producer

  @impl Producer
  def prepare_for_start(module, opts) do
  end

  @impl Producer
  def prepare_for_draining(%{receive_timer: receive_timer} = state) do
  end

  @impl GenStage
  def init(opts) do
  end

  @impl GenStage
  def handle_demand(incoming_demand, %{demand: demand} = state) do
    handle_receive_messages(%{state | demand: demand + incoming_demand})
  end

  defp handle_receive_messages(%{demand: demand} = state) when demand > 0 do
    messages = receive_messages_from_queue(state, demand)
    new_demand = demand - length(messages)

    {:noreply, messages, %{state | demand: new_demand}}
  end

  defp handle_receive_messages(state) do
    {:noreply, [], state}
  end

  defp receive_messages_from_queue(state, demand) do
  end
end
