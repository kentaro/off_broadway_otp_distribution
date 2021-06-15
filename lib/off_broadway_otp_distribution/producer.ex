defmodule OffBroadwayOtpDistribution.Producer do
  use GenStage
  require Logger

  alias Broadway.Producer
  @behaviour Producer

  @default_receive_interval 3_000

  @impl Producer
  def prepare_for_start(_module, broadway_options) do
     children = [
       {DynamicSupervisor, strategy: :one_for_one, name: OffBroadwayOtpDistribution.DynamicSupervisor}
     ]
     {children, broadway_options}
  end

  @impl GenStage
  def init(opts) do
    DynamicSupervisor.start_child(
      OffBroadwayOtpDistribution.DynamicSupervisor, {
        OffBroadwayOtpDistribution.Receiver,
        opts[:receiver] ++ [producer: self()],
      }
    )

    {:producer, %{
      demand: 0,
      receive_timer: nil,
      receive_interval: opts[:receive_interval] || @default_receive_interval
    }}
  end

  @impl GenStage
  def handle_demand(_incoming_demand, state) do
    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info({:receive_messages, messages}, state) do
    {:noreply, messages, state}
  end

  # @impl GenStage
  # def handle_demand(incoming_demand, %{demand: demand} = state) do
  #   handle_receive_messages(%{state | demand: demand + incoming_demand})
  # end

  # @impl GenStage
  # def handle_info(:receive_messages, state) do
  #   handle_receive_messages(%{state | receive_timer: nil})
  # end

  # defp handle_receive_messages(%{receive_timer: nil, demand: demand} = state) when demand > 0 do
  #   messages = receive_messages_from_queue(demand)
  #   new_demand = demand - length(messages)

  #   receive_timer =
  #     case {messages, new_demand} do
  #       {[], _} -> schedule_receive_messages(state.receive_interval)
  #       {_, 0} -> nil
  #       _ -> schedule_receive_messages(0)
  #     end

  #   {:noreply, messages, %{state | demand: new_demand, receive_timer: receive_timer}}
  # end

  # defp handle_receive_messages(state) do
  #   {:noreply, [], state}
  # end

  # defp schedule_receive_messages(interval) do
  #   Process.send_after(self(), :receive_messages, interval)
  # end

  # defp receive_messages_from_queue(demand) do
  #   OffBroadwayOtpDistribution.Queue.dequeue(demand)
  # end
end
