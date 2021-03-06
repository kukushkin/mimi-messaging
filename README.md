# mimi-messaging

Interservice communication via message bus for microservices.

## Is it production ready?

No. Consider this project a WIP.

## What

`mimi-messaging` is a Messaging layer -- an interservice
communication layer based on message bus, for connecting microservice applications.

* Command, Query, Event communication patterns
* "at-least-once" message delivery guarantees
* Abstract message bus interface, not bound to specific message broker implementation

See also: [Overview of Messaging layer properties](docs/Messaging_Layer_Properties.md)

## Why

When it comes to organizing communications between different microservices of a system,
currently there is only two options: to use HTTP or a message bus.

[Why HTTP is a bad choice for interservice communication?](docs/Why_HTTP_is_a_bad_choice.md)

TBD: Message bus pro's and con's.

## How

Concepts:

* Command: one-to-one, send and forget
* Query: one-to-one, call and wait for response
* Event: one-to-many, broadcast

## Setup

```
gem "mimi-messaging", "~> 1.0"
gem "mimi-messaging-<ADAPTER>"
```

```
require "mimi/messaging"
require "mimi/messaging/<ADAPTER>"

Mimi::Messaging.use serializer: Mimi::Messaging::JsonSerializer
Mimi::Messaging.configure mq_adapter: "<ADAPTER>", ... # extra adapter specific options
Mimi::Messaging.start
```

## Usage

Producing messages:
```
# COMMAND
Mimi::Messaging.command("users/lock", id: "b3cc29c8d2ec68e0")

# QUERY
response = Mimi::Messaging.query("orders/show", id: 123)

# EVENT
```

See (/examples)[/examples] folder for more examples on how to produce and consume messages.


## Adapters

`mimi-messaging` is not bound to a specific message broker implementation like RabbitMQ or Kafka. It interacts with a message broker using an adapter interface and
there are several available adapters:

* [Kafka](https://github.com/kukushkin/mimi-messaging-kafka)
* RabbitMQ (TBD)
* NATS (TBD)
* [Amazon SQS/SNS](https://github.com/kukushkin/mimi-messaging-sqs_sns)
* (in-memory (single process))[lib/mimi/messaging/adapters/memory.rb]

## Designing apps


There are only two hard problems in distributed systems:

```
2. Exactly-once delivery
1. Guaranteed order of messages
2. Exactly-once delivery
```


[Messaging API specification format](https://github.com/kukushkin/mimi-messaging-spec)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

