# scala-akka-microservice-example
An example microservice written in Scala exposed using the Akka toolkit.

This is project was designed to supplement my [blog post on Docker, Ansible and AWS](http://danielrhoades.com/docker-aws-ansible).

It comprises of the following sub-components:

* Scala application which prints the ubiquitous "Hello World";
* Akka HTTP service wrapping the above application;
* Unit tests using ScalaTest.

I borrowed the concepts from another project [Iterators - Akka HTTP microservice example](https://github.com/theiterators/akka-http-microservice).
