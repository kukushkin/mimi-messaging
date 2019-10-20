# [WIP] Why HTTP is a bad choice for interservice communication

Downsides of HTTP:
* inherently synchronous
  * timeouts
  * retries
* one-to-one, no pub/sub
* additional work required:
  * network
  * service discovery
  * routing
  * load balancing
  * authentication/authorization


Pro's of HTTP:
* synchronous communication is simple
* HTTP as technology is well known by engineers
* more stable and simpler to setup if the services are not closely deployed (e.g. in different datacenters/regions)

