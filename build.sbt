import sbt._
import sbt.Keys._

import _root_.io.gatling.build.license.ApacheV2License

kotlinVersion := "2.1.0"
scalaVersion := "2.13.16"

enablePlugins(GatlingAutomatedScalafmtPlugin)
scalafmtOnCompile := false

enablePlugins(GatlingCompilerSettingsPlugin)

enablePlugins(AutomateHeaderPlugin)
headerLicense := ApacheV2License

Compile / javacOptions ++= Seq("-encoding", "utf8")
Test / javacOptions ++= Seq("-encoding", "utf8")
Test / javacOptions += "-Xlint:unchecked"
Test / unmanagedSourceDirectories ++= (baseDirectory.value / "content" ** "code").get

// Dependencies

val gatlingVersion = "3.13.3"
val gatlingGrpcVersion = "3.13.3"
val gatlingMqttVersion = "3.13.3"

libraryDependencies ++= Seq(
  // Gatling modules
  "io.gatling" % "gatling-core-java"  % gatlingVersion,
  "io.gatling" % "gatling-http-java"  % gatlingVersion,
  "io.gatling" % "gatling-jms-java"   % gatlingVersion,
  "io.gatling" % "gatling-jdbc-java"  % gatlingVersion,
  "io.gatling" % "gatling-redis-java" % gatlingVersion,
  // External Gatling modules
  "io.gatling" % "gatling-grpc-java" % gatlingGrpcVersion,
  "io.gatling" % "gatling-mqtt-java" % gatlingMqttVersion,
  // Other
  "org.apache.commons"     % "commons-lang3"   % "3.17.0",
  "commons-codec"          % "commons-codec"   % "1.17.2",
  "software.amazon.awssdk" % "secretsmanager"  % "2.30.3",
  ("org.apache.activemq"   % "activemq-broker" % "5.18.6" % Test)
    .exclude("jakarta.jms", "jakarta.jms-api")
)