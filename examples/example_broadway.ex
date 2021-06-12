defmodule ExampleBroadway do
  use Broadway
  require Logger

  def start_link(_opts \\ []) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {OffBroadwayOtpDistribution.Producer, []}
      ],
      processors: [
        default: [concurrency: 2]
      ],
    )
  end

  @impl Broadway
  def handle_message(:default, msg, _context) do
    Logger.info("handled: #{inspect(msg)}")
  end
end
