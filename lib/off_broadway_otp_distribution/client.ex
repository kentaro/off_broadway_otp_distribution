defmodule OffBroadwayOtpDistribution.Client do
  @doc """
  A base module for implementing the client for `OffBroadwayOtpDistribution.Receiver`.

  ## Example

  The client process implemented using this module communicates to the receiver process
  implemented as `OffBroadwayOtpDistribution.Receiver` via message passings each other.

  If the producer implemented as `OffBroadwayOtpDistribution.Producer` runs on `:pull` mode
  and the demand it has is not fully met,
  it sends `:pull_message` message to the client via the receiver.
  You must implement a callback for the message if the producer runs on `:pull` mode.

  If the producer runs on `:push` mode, you can freely push a message
  regardless of whether the Broadway producer has demand or not.

  ```
  defmodule ExamplesClient do
    use OffBroadwayOtpDistribution.Client

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

    def start(opts \\ []) do
      [
        {__MODULE__, opts}
      ]
      |> Supervisor.start_link(
        strategy: :one_for_one,
        name: ExamplesClient.Supervisor
      )
    end

    def push_message(message) do
      GenServer.cast(__MODULE__, {:push_message, message})
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger

      @default_receiver_name :off_broadway_otp_distribution_receiver
      @default_max_retry_count 10

      @impl GenServer
      def init(opts \\ []) do
        receiver_name = opts[:receiver_name] || @default_receiver_name
        max_retry_count = opts[:max_retry_count] || @default_max_retry_count
        receiver = connect_to_receiver(receiver_name, max_retry_count)

        {:ok,
         %{
           receiver: receiver
         }}
      end

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl GenServer
      def handle_info({:DOWN, _, _, _, reason}, state) do
        Logger.error("Server is down: #{reason}")
        {:noreply, %{state | receiver: nil}}
      end

      @impl GenServer
      def terminate(reason, state) do
        Logger.error("Client is terminating: #{inspect(reason)}")
      end

      defp connect_to_receiver(receiver_name, retry_count) do
        receiver = try_connect_to_receiver(receiver_name, retry_count)

        GenServer.call(receiver, :register)
        Logger.info("Register this client to #{inspect(receiver)}")

        # To reboot this process when the receiver process terminates
        Process.monitor(receiver)

        receiver
      end

      defp try_connect_to_receiver(receiver_name, retry_count) do
        if retry_count > 0 do
          :global.sync()
          receiver = :global.whereis_name(receiver_name)

          if receiver == :undefined do
            Logger.debug("Waiting for the receiver is up.")
            Process.sleep(500)
            try_connect_to_receiver(receiver_name, retry_count - 1)
          else
            receiver
          end
        else
          raise("Couldn't connect to #{receiver_name}")
        end
      end
    end
  end
end
