defmodule ExamplesBroadway do
  use Broadway
  require Logger

  def start_link(opts \\ []) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {OffBroadwayOtpDistribution.Producer,
           [
             mode: opts[:mode],
             receiver: [
               name: :off_broadway_otp_distribution_receiver
             ]
           ]},
        rate_limiting: [
          # This option is supposed to be set to the count of client nodes.
          allowed_messages: 1,
          interval: 1_000
        ]
      ],
      processors: [
        default: [
          concurrency: 1,
          # This option is supposed to be set to the count of client nodes.
          max_demand: 1,
          min_demand: 0
        ]
      ]
    )
  end

  @impl Broadway
  def handle_message(_, msg, _context) do
    Logger.debug("handle_message: #{inspect(msg)}")
    msg
  end
end
