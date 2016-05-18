# greeter-service-example
An example microservice written in Scala exposed using the Akka toolkit.

This is project was designed to supplement my [blog post on Docker, Ansible and AWS](http://danielrhoades.com/docker-aws-ansible).

The solution has been designed to address the following challenge:

> Provide a service which can accept a person's first and last name, then return them a greeting in the format of "Hello \<firstName\> \<lastName\>".  The service should be exposed as REST API which is asynchronous and non-blocking.

It comprises of the following sub-components:

* Scala application which prints the ubiquitous "Hello World";
* Akka HTTP service wrapping the above application;
* Unit tests using ScalaTest.

I borrowed the concepts from another project [Iterators - Akka HTTP microservice example](https://github.com/theiterators/akka-http-microservice).

On the face of things this looks like an over-complex solution to the challenge.  It is.  However, it provides a useful foundation for understanding and testing Scala/Akka HTTP microservice integrations. 

Also, you'll notice that there would seem to be a lot of boiler plate code, I'll address this issue in the next example.

## Design

### Interface

The interface will accept a single POST request of JSON data to the `/greeting` resource.  A `GreetingRequest` will comprise of a person's first and last names as separate key/value string pairs.  A valid request though should look like this as an example:

```
$ curl -X POST -H 'Content-Type: application/json' http://localhost:9000/greeting -d '{"firstName": "Bob", "lastName": "Smith"}'
```

The expected `GreetingResponse` should also be in JSON format, with the greeting message as a single key/value string pair, for example:

```
{
  "message": "Hello Bob Smith"
}
```

### Message Model

The `GreetingRequest` and `GreetingResponse` messages will be interally modelled as case cases based on interface specification above.  The application will define implicit variables to handle the marshalling/unmarshalling. 

### Application Logic

The actual application logic will be modelled as the object `GreetingLogic`, it will simply concatenate a configurable greeting message with the given person's first and last names.

### Service

A `Service` trait will provide the routing and request handling logic.  It will define an Akka HTTP route for handling requests based on the interface specification.  The `Service` will wrap calls to `GreetingLogic` in a Future to enable asynchronous operation using the Actor model.  It should either return the `GreetingResponse` or an error message with a 400 status.
 
The `AkkaHttpMicroservice` will operate as the executable App extending the `Service` and using the Akka HTTP toolkit (streams and http DSL) to bind the App to a configurable IP address/port.  The default request timeout (20 seconds) is acceptable.

## Building and Testing

SBT is used to build the project:

```
$ sbt
> compile
```

ScalaTest Specifications are used to unit test at the Service level:

```
$ sbt
> test
```

The application can be started using the [Spray sbt-revolver plugin](https://github.com/spray/sbt-revolver):

```
$ sbt
> ~re-start
```

The `~` will cause the plugin to enter "triggered restart" so that any changes to the source code will be picked up and the service restarted.  This is extremely useful for rapid development.

## Packaging

To build a "fat" JAR with all the dependencies:

```
$ sbt
> assembly
```

The project also has a Docker file based on [Alpine Linux](http://www.alpinelinux.org/) (a lightweight, security-oriented Linux distro), built around muslc libc and busybox it is only ~130MB in size.  The standard [Oracle JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html) is also used.  Even better, somebody has already put this all together as a Docker image [frolvlad/alpine-oraclejdk8](https://hub.docker.com/r/frolvlad/alpine-oraclejdk8/) weighing in ~170MB, so our Dockerfile is built on top of that.

To build the Docker image:

```
$ docker build -t greeter-service-example .
```

Total size of all the Docker layers is ~190MB - which less than a full Oracle JDK download.

## Running

To run the packaged "fat" JAR:

```
$ java -jar target/scala-2.11/greeter-service-example-assembly-0.1.jar
```

Or if you have built the Docker image:

```
$ docker run greeter-service-example -p 9000:9000
```