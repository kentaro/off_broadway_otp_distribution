defmodule OffBroadwayOtpDistribution.Producer do
  use GenStage

  alias Broadway.Producer
  alias Broadway.Message

  @behaviour Producer

  @impl GenStage
  def init(opts) do
    {:producer, opts}
  end

  @impl GenStage
  def handle_demand(demand, state) do
    handle_receive_messages(demand, state)
  end

  defp handle_receive_messages(demand, state) when demand > 0 do
    messages = retrieve_messages_from_queue(demand)
    {:noreply, messages, state}
  end

  defp handle_receive_messages(_demand, state) do
    {:noreply, [], state}
  end

  defp retrieve_messages_from_queue(demand) do
    OffBroadwayOtpDistribution.Queue.dequeue(demand)
    |> Enum.map(fn message ->
      %Message{
        data: message,
        acknowledger: {Broadway.NoopAcknowledger, nil, nil}
      }
    end)
  end
end
