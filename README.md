# greeter-service-example
An example microservice written in Scala exposed using the Akka toolkit deployed using Ansible into AWS.

This is project was designed to supplement my [blog post on Docker, Ansible and AWS](http://danielrhoades.com/docker-aws-ansible).

The solution has been designed to address the following challenge:

> Provide a service which can accept a person's first and last name, then return them a greeting in the format of "Hello \<firstName\> \<lastName\>".  The service should be exposed as REST API which is asynchronous and non-blocking.

It comprises of the following sub-components:

* Scala application which prints the ubiquitous "Hello World";
* Akka HTTP service wrapping the above application;
* Unit tests using ScalaTest.

I borrowed the concepts of the service from another project [Iterators - Akka HTTP microservice example](https://github.com/theiterators/akka-http-microservice).

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

### Platform

The packaged application will be deployed as a [Docker](https://docs.docker.com/engine/understanding-docker/) container.

The application will be provisioned into a cloud hosting model making best use of [IaaS (Infrastructure as a Service)](https://en.wikipedia.org/wiki/Cloud_computing#Infrastructure_as_a_service_.28IaaS.29) and [PaaS (Platform as a Service)](https://en.wikipedia.org/wiki/Platform_as_a_service).  Specifically this application will use [AWS](https://aws.amazon.com) with the following services:
 
* Compute: [Autoscaling Group](http://docs.aws.amazon.com/autoscaling/latest/userguide/WhatIsAutoScaling.html) with EC2, and [EC2 Container Service (ECS)](https://aws.amazon.com/ecs/);
* Networking: [VPC](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html), [Elastic Load Balancers (ELB)](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elastic-load-balancing.html), [Route 53](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html).

The Docker container containing the application will be deployed as a Service within ECS accessed via an ELB.  All services where applicable will be deployed into a VPC.  Access to the application will be via a friendly DNS alias which will be provisioned on Route 53.

The service is expected to be resilient to failure, so will operate across at least 2 Availability Zones (AZs).

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

## Deployment

To provision this project into AWS you will need an Ansible environment, currently the script depending on bleeding edge Ansible, e.g. the devel branch.
 
Do the following to get a devel version of Ansible configured with AWS support:

1. Clone this project;
2. Clone the following project [daniel-rhoades/ansible-environment](https://github.com/daniel-rhoades/ansible-environment), this will give you the necessary Ansible environment as a virtual machine.  It might take a while as it builds Ansible from source and so needs a lot of dependencies not in the standard Ubuntu image; 
3. Provision a Vagrant environment by running `$ vagrant up development` in the `ansible-environment` project root directory
4. SSH into Vagrant (`$ vagrant ssh development`), your host home directory will be mapped to the directory in the Vagrant virtual machine as `/home/host-machine`

Now get an AWS account (if you don't already have one) and get some basic stuff setup:

5. Register for an AWS account, create an IAM user, download the access/secret key and attach the following AWS IAM policy to that user:
    * `AdministratorAccess`;
6. Within the AWS console, create an [SSH Key Pair](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#KeyPairs:sort=keyName), this will be the key given to all EC2 instances, note the name you give to this Key Pair;
    * I will encorporate this into the playbook soon
7. Run through the [ECS Getting Started](https://eu-west-1.console.aws.amazon.com/ecs/home?region=eu-west-1#/firstRun), on step 2 choose the ELB option, then just keep clicking next;
    * This is needed just to create the initial ECS roles;
    * I will encorporate this into the playbook soon

Setup your environment for this project:

8. `cd` into this project's `deploy` directory (remember your home dir is located under `/home/host-machine` in Vagrant), source your AWS environment by running `$ eval "$(./aws-ansible.sh <my-access-key> <my-secret-key> <region>)"` replacing the placeholder values with the access/secret key you just created and use whatever region you want;
9. Install the required roles from Ansible Galaxy: `$ sudo ansible-galaxy install -r requirements.yml`

Now to deploy this project, back within the Vagrant SSH session:

10. Provision the environment by running: `$ ansible-playbook provision-aws.yml -e ssh_key_name=<ssh-key-name> -e my_route53_zone=<your-domain>`, replacing the placeholders with your key name and the name of a domain you have created in AWS Route 53 (just use example.com if you don't have one).  If you get an error try re-running the command, there are some Ansible bugs...;

Finally, just try and use the service:

```
$ curl -X POST -H 'Content-Type: application/json' http://greeter-development.<your-domain>/greeting -d '{"firstName": "Bob", "lastName": "Smith"}'
```

The expected response is:

```
{
  "message": "Hello Bob Smith"
}
```

You don't have to access this via the domain registered with Route 53 you can just get the alias for the ELB within the AWS console.

From scratch provisioning will take around 1 minute.  But the service will probably take a couple of minutes to become available.

All logs can be viewed under AWS [CloudWatch](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatchLogs.html), all logs from instances are collected here.  The applications logs can be found under the Log Group `greeter-development_/var/log/messages` currently Docker has been configured to place all log messages for each instance under `/var/log/messages`.

In the future ECS will support logging and collection for multiple files rather than having to dump all the logs in one place.  This isn't a major problem though as ECS has been configured to tag each log entry is the Docker image name.

## Maintenance

The Greeter service can be linearly scaled by using one of these methods:

1. Number of EC2 instances can be configured by re-running this playbook and overriding the `greeter_ec2_asg_desired_capacity` and `greeter_ec2_asg_max_size` variables, e.g. just pass them into the playbook using the `-e` option in the same way of the `ssh_key_name`
2. Login to the AWS console and change the same logical settings in the Auto Scaling Group under the EC2 module;
3. Configure an auto-scaling policy to increase the number of EC2 instances based on a metric like CPU load.

This will increase the available capacity but wont directly increase the number of copies of the service running.  To do that either:

1. Number of copies of the Greeter service can be set using the playbook variable `greeter_ecs_task_definition_count`;
2. Login to the AWS console and change the same logical setting (Desired Count) on the ECS Service within the EC2 Container Service (ECS) module.

The solution is setup to be self healing.  The ELBs will detect failures and work with ECS and EC2 Auto Scaling to remove failing instances and create new healthy ones.

In a future article I will talk about setting up autoscaling to happen automatically, both for the EC2 instance and Service desired copy counts based on metrics.