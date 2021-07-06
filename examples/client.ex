defmodule ExamplesClient do
  use OffBroadwayOtpDistribution.Client

  @doc """
  ## `:pull_message`

  If the `OffBroadwayOtpDistribution.Producer` runs on `:pull` mode,
  the producer send `:pull_message` to the client.

  ## `:push_message`

  If the `OffBroadwayOtpDistribution.Producer` runs on `:push` mode,
  you can freely push a message regardless of whether the producer has demand or not.
  """
  @impl GenServer
  def handle_cast(:pull_message, state) do
    Logger.debug("received: :pull_message")
    GenServer.cast(state.receiver, {:send_message, "I'm alive!"})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:push_message, message}, state) do
    GenServer.cast(state.receiver, {:push_message, message})
    {:noreply, state}
  end

  # Helper API

  @doc """
  You must put the client under a supervison of `Supervisor` in case that
  the client process terminates.
  """
  def start(opts \\ []) do
    [
      {__MODULE__, opts}
    ]
    |> Supervisor.start_link(
      strategy: :one_for_one,
      name: ExamplesClient.Supervisor
    )
  end

  @doc """
  You can push a message via message casting regardless whether of the Broadway producer has demand or not,
  if the `OffBroadwayOtpDistribution.Producer` runs on `:push` mode,
  """
  def push_message(message) do
    GenServer.cast(__MODULE__, {:push_message, message})
  end
end
