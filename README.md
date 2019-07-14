# [WIP] mimi-messaging

Interservice communication via message bus for microservices.

## What

`mimi-messaging` is a Messaging layer -- an interservice
communication layer based on message bus, for connecting microservice applications.

* Command, Query, Event communication patterns
* "at-least-once" message delivery guarantees
* Abstract message bus interface, not bound to specific message broker implementation

See also: [Overview of Messaging layer properties](docs/Messaging_Layer_Properties.md)

## Why

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

```
response = Mimi::Messaging.query("orders/show", id: 123)
```

## Adapters

`mimi-messaging` is not bound to a specific message broker implementation like RabbitMQ or Kafka. It interacts with a message broker using an adapter interface and
there are several available adapters:

* [Kafka](https://github.com/kukushkin/mimi-messaging-kafka)
* RabbitMQ (TBD)
* NATS (TBD)
* Amazon SQS/SNS
* in-memory (single process)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

