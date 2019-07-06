# [WIP] mimi-messaging

Interservice communication via message bus for microservices.

## What

Mimi::Messaging is a messaging layer for microservice applications.

It abstracts the message bus interface, offering you the most common communication
patterns with "at-least-once" message delivery guarantees.

## Why

[Why HTTP is a bad choice for interservice communication?](docs/Why_HTTP_is_a_bad_choice.md)

TBD: Message bus pro's and con's.

## How

Concepts:

* Command: one-to-one, send and forget
* Query: one-to-one, call and wait for response
* Event: one-to-many, broadcast

## Setup

## Usage

## Adapters

* Memory (single process)
* RabbitMQ
* Kafka
* NATS
* Amazon SNS/SQS

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

