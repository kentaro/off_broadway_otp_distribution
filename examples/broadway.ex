defmodule ExamplesBroadway do
  use Broadway
  require Logger

  def start_link(_opts \\ []) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {OffBroadwayOtpDistribution.Producer, [
          receiver: [
            name: :off_broadway_otp_distribution_receiver,
          ],
        ]},
      ],
      processors: [
        default: [
          concurrency: 1,
        ]
      ],
    )
  end

  @impl Broadway
  def handle_message(_, msg, _context) do
    Logger.info("handled: #{inspect(msg)}")
    msg
  end
end
