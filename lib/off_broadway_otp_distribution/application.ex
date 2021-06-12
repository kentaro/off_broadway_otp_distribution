defmodule OffBroadwayOtpDistribution.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    [
      {OffBroadwayOtpDistribution.Receiver, []},
      {OffBroadwayOtpDistribution.Queue, []},
    ]
    |> Supervisor.start_link(
      strategy: :one_for_one,
      name: OffBroadwayOtpDistribution.Supervisor
    )
  end
end
