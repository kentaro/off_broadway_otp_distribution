defmodule ExampleBroadway do
  use Broadway
  require Logger

  alias Broadway.Message

  def start_link(_opts \\ []) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {OffBroadwayOtpDistribution.Producer, [
          receiver: [
            name: :off_broadway_otp_distribution_receiver,
          ],
        ]},
        rate_limiting: [
          allowed_messages: 10,
          interval: 1_000
        ],
        concurrency: 1,
      ],
      processors: [
        default: [concurrency: 1]
      ],
    )
  end

  @impl Broadway
  def handle_message(_, msg, _context) do
    Logger.debug("handled: #{inspect(msg)}")
    msg
  end
end
