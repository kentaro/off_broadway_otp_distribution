# OffBroadwayOtpDistribution

An OTP distribution connector for [Broadway](https://github.com/dashbitco/broadway).

## Installation

Add `off_broadway_otp_distribution` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:off_broadway_otp_distribution, "~> 0.1.0", github: "kentaro/off_broadway_otp_distribution", branch: "main"}
  ]
end
```

## How it works

This module provides an OTP distribution connector for Broadway. Using this module, a Broadway process can receive messages via inter-processes communication that supports both `pull` and `push` modes.

If the producer runs on `:pull` mode and the demand it has is not fully met, it sends `:request_message` message to the client via the receiver. You must implement a callback for the message to your client if the producer runs the mode.

If the producer runs on `:push` mode, you can freely push a message via `:push_message` regardless of whether the Broadway producer has demand or not.

## Usage

### Setup nodes

To give a try to this module, you can setup two nodes beforehand.

(1) Server node:

```
$ iex --sname server@localhost -S mix
```

(2) Client node:

```
$ iex --sname client@localhost -S mix
```

Then connect each other:

```
iex(client@localhost)1> Node.connect(:server@localhost)
true
iex(client@localhost)2> Node.list
[:server@localhost]
```

### Push mode

Firstly, start the Broadway process using [examples/broadway.ex](examples/broadway.ex). Notice that the option passed to `ExamplesBroadway.start_link/1` is `mode: :push` that is to make the Broadawy producer run on `push` mode.

```
iex(server@localhost)1> import_file("examples/broadway.ex")
iex(server@localhost)2> ExamplesBroadway.start_link(mode: :push)
```

Secondly, start the client process using [examples/client.ex](examples/client.ex). To push a message to the Broadway process, use a utility function named `ExamplesClient.push_message/1`.

```
iex(client@localhost)3> import_file("examples/client.ex")
iex(client@localhost)4> ExamplesClient.start
iex(client@localhost)5> ExamplesClient.push_message("How are you?")
:ok
```

Then, you can see the message is pushed to the Broadway process.

```
iex(server@localhost)3>
00:56:37.689 [info]  register: {#PID<20467.227.0>, [:alias | #Reference<20467.3437655963.3701014534.187758>]}

00:57:14.092 [info]  push_message: "How are you?"

00:57:14.094 [info]  handled: %Broadway.Message{acknowledger: {Broadway.NoopAcknowledger, nil, nil}, batch_key: :default, batch_mode: :bulk, batcher: :default, data: "How are you?", metadata: %{}, status: :ok}
```

### Pull mode

Start the both server and client processes same as above. Notice that the option passed to `ExamplesBroadway.start_link/1` is `mode: :pull` that is to make the Broadawy producer run on `pull` mode.

```
iex(server@localhost)1> import_file("examples/broadway.ex")
iex(server@localhost)2> ExamplesBroadway.start_link(mode: :pull)
```

```
iex(client@localhost)2> import_file("examples/client.ex")
iex(client@localhost)3> ExamplesClient.start
```

Then, you'll see the Broadway process pulls messages from the client to meet the demand.

```
iex(server@localhost)3>
01:11:32.117 [info]  pull_messages: {#PID<0.225.0>, [:alias | #Reference<0.1827069120.2629894145.158617>]}

01:11:32.117 [info]  request_message: {#PID<19681.225.0>, [:alias | #Reference<19681.3788998035.3703898113.21779>]}

01:11:32.117 [info]  respond_to_pull_request: "I'm alive!"

01:11:32.125 [info]  handled: %Broadway.Message{acknowledger: {Broadway.NoopAcknowledger, nil, nil}, batch_key: :default, batch_mode: :bulk, batcher: :default, data: "I'm alive!", metadata: %{}, status: :ok}

(... snip ...)
```

## Author

[Kentaro Kuribayashi](https://kentarokuribayashi.com/)

## License

MIT
