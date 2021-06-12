defmodule OffBroadwayOtpDistribution.Queue do
  use GenServer

  @impl GenServer
  def init(state \\ []) do
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  @impl GenServer
  def handle_call(:dequeue, _from, []) do
    {:reply, nil, []}
  end

  @impl GenServer
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  @impl GenServer
  def handle_call({:dequeue, demand: _demand}, _from, []) do
    {:reply, [], []}
  end

  @impl GenServer
  def handle_call({:dequeue, demand: demand}, _from, state) do
    {values, state} = Enum.split(state, demand)
    {:reply, values, state}
  end

  @impl GenServer
  def handle_call(:queue, _from, state) do
    {:reply, state, state}
  end

  # Helper APIs

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def enqueue(value) do
    GenServer.cast(__MODULE__, {:enqueue, value})
  end

  def dequeue(demand) when demand > 0 do
    GenServer.call(__MODULE__, {:dequeue, demand: demand})
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  def queue do
    GenServer.call(__MODULE__, :queue)
  end
end
