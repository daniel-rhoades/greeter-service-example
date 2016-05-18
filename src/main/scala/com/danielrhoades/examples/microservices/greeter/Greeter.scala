package com.danielrhoades.examples.microservices.greeter

import akka.actor.ActorSystem
import akka.event.{Logging, LoggingAdapter}
import akka.http.scaladsl.Http
import akka.http.scaladsl.marshallers.sprayjson.SprayJsonSupport
import akka.http.scaladsl.model.StatusCodes._
import akka.http.scaladsl.server.Directives._
import akka.stream.{ActorMaterializer, Materializer}
import com.typesafe.config.{Config, ConfigFactory}
import spray.json.DefaultJsonProtocol

import scala.concurrent.{ExecutionContextExecutor, Future}
import scala.util.{Failure, Success}

/**
  * Service request for a greeting message
  *
  * @param firstName
  * @param lastName
  */
case class GreetingRequest(firstName: String, lastName: String)

/**
  * Service response for a greeting message
  *
  * @param message
  */
case class GreetingResponse(message: String)

/**
  * Business logic that will determine the greeting message
  */
object GreetingLogic {
  val config: Config = ConfigFactory.load()

  /**
    * Generates the greeting response
    *
    * @param firstName
    * @param lastName
    * @return future
    */
  def apply(firstName: String, lastName: String): GreetingResponse =
    GreetingResponse(s"${config.getString("services.message-prefix")} $firstName $lastName")
}

/**
  * Defines the JSON formatter for all our message types to support implicit marshalling/unmarshalling
  */
trait Protocols extends SprayJsonSupport with DefaultJsonProtocol {
  implicit val greetingRequestFormat = jsonFormat2(GreetingRequest.apply)
  implicit val greetingResponseFormat = jsonFormat1(GreetingResponse.apply)
}

/**
  * Defines an asynchronous non-blocking service to process Greeting requests
  */
trait Service extends Protocols {
  implicit val system: ActorSystem
  implicit def executor: ExecutionContextExecutor
  implicit val materializer: Materializer

  def config: Config = ConfigFactory.load()
  val logger: LoggingAdapter

  /**
    * Wraps the GreetingLogic with a Future.  The GreetingLogic can do this itself because it doesn't have the context.
    * @param greetingRequest
    * @return
    */
  def fetchGreeting(greetingRequest: GreetingRequest): Future[GreetingResponse] = {
    Future(GreetingLogic(greetingRequest.firstName, greetingRequest.lastName))
  }

  /**
    * Defines how HTTP requests and responses should be handled.
    */
  val routes = {
    logRequestResult(config.getString("services.name")) {
      pathPrefix("greeting") {
        (post & entity(as[GreetingRequest])) { greetingRequest =>
          onComplete(fetchGreeting(greetingRequest)) {
            case Success(value) => complete(OK, value)
            case Failure(ex: IllegalArgumentException) => complete(BadRequest -> ex.getMessage)
            case Failure(ex) => complete(InternalServerError -> ex.getMessage)
          }
        }
      }
    }
  }
}

/**
  * Runs the Akka HTTP toolkit around the Service
  */
object AkkaHttpMicroservice extends App with Service {
  override implicit val system = ActorSystem()
  override implicit val executor = system.dispatcher
  override implicit val materializer = ActorMaterializer()

  override val logger = Logging(system, getClass)

  Http().bindAndHandle(routes, config.getString("http.interface"), config.getInt("http.port"))
}




