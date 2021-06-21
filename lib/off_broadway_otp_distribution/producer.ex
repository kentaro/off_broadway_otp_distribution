defmodule OffBroadwayOtpDistribution.Producer do
  use GenStage
  require Logger

  alias Broadway.Producer
  @behaviour Producer

  @default_producer_mode :push
  @default_pull_interval 5_000

  @impl Producer
  def prepare_for_start(_module, opts) do
    concurrency = opts[:producer][:concurrency] || 1

    if concurrency > 1 do
      raise("#{__MODULE__} currently supports only a single instance.")
    end

    children = [
      {DynamicSupervisor,
       strategy: :one_for_one, name: OffBroadwayOtpDistribution.DynamicSupervisor}
    ]

    {children, opts}
  end

  @impl GenStage
  def init(opts) do
    mode = opts[:mode] || @default_producer_mode

    {:ok, receiver} =
      DynamicSupervisor.start_child(
        OffBroadwayOtpDistribution.DynamicSupervisor,
        {
          OffBroadwayOtpDistribution.Receiver,
          opts[:receiver] ++
            [
              producer: self(),
              mode: mode
            ]
        }
      )

    {:producer,
     %{
       demand: 0,
       mode: mode,
       receiver: receiver,
       pull_timer: nil,
       pull_interval: opts[:pull_interval] || @default_pull_interval
     }}
  end

  @impl GenStage
  def handle_demand(incoming_demand, %{demand: demand} = state) do
    case state.mode do
      :push -> handle_push_messages(state)
      :pull -> handle_pull_messages(%{state | demand: demand + incoming_demand})
    end
  end

  @impl GenStage
  def handle_info({:push_messages, messages}, state) do
    {:noreply, messages, state}
  end

  @impl GenStage
  def handle_info(:pull_messages, state) do
    handle_pull_messages(%{state | pull_timer: nil})
  end

  @impl GenStage
  def handle_info({:respond_to_pull_request, messages}, %{demand: demand} = state) do
    {:noreply, messages, %{state | demand: demand - length(messages)}}
  end

  @impl GenStage
  def handle_info(_, state) do
    {:noreply, [], state}
  end

  defp handle_push_messages(state) do
    {:noreply, [], state}
  end

  defp handle_pull_messages(%{demand: demand} = state) when demand > 0 do
    1..demand |> Enum.each(fn _ -> request_pull_messages(state) end)
    pull_timer = schedule_pull_messages(state.pull_interval)

    {:noreply, [], %{state | pull_timer: pull_timer}}
  end

  defp handle_pull_messages(state) do
    {:noreply, [], state}
  end

  defp request_pull_messages(state) do
    GenServer.call(state.receiver, :pull_messages)
  end

  defp schedule_pull_messages(interval) do
    Process.send_after(self(), :pull_messages, interval)
  end
end
