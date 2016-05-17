package com.danielrhoades.examples.microservices.greeter

import akka.event.NoLogging
import akka.http.scaladsl.model.ContentTypes._
import akka.http.scaladsl.model.StatusCodes._
import akka.http.scaladsl.testkit.ScalatestRouteTest
import org.scalatest._

class ServiceSpec extends FlatSpec with Matchers with ScalatestRouteTest with Service {
  override def testConfigSource = "akka.loglevel = WARNING"
  override def config = testConfig
  override val logger = NoLogging

  val bobSmithGreeting = GreetingResponse("Hello Bob Smith")

  "Service" should "respond to a valid firstName/lastName submission" in {
    Post(s"/greeting", GreetingRequest("Bob", "Smith")) ~> routes ~> check {
      status shouldBe OK
      contentType shouldBe `application/json`
      responseAs[GreetingResponse] shouldBe bobSmithGreeting
    }
  }
}
