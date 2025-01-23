---
menutitle: Open-source Plugin
title: Open-source Jenkins Plugin
seotitle: Open-Source Jenkins Plugin for Gatling
description: How to use the Jenkins plugin to set up your load tests in your Continuous Integration pipelines.
lead: Open-source Jenkins CI plugin for Gatling
aliases:
  - /reference/extensions/ci-cd/jenkins/oss
date: 2021-04-20T18:30:56+02:00
lastmod: 2022-12-14T21:30:56+02:00
---

Thanks to this plugin, you can track a Gatling simulation launched by the Maven plugin in Jenkins.

## Getting Gatling Jenkins plugin

Gatling Jenkins plugin is available in Jenkins plugin manager.

You can also get Gatling Jenkins plugin as a `.hpi` file [here](http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/gatling).

Source code is hosted in a dedicated project: [gatling-plugin](https://github.com/jenkinsci/gatling-plugin).

## Installing Gatling Jenkins plugin in Jenkins

You can install the plugin manually by following the official Jenkins documentation [here](https://jenkins.io/doc/book/managing/plugins/#installing-a-plugin).

## Jenkins plugin usage

Documentation of Gatling Jenkins plugin is available on the [jenkins.io website](https://plugins.jenkins.io/gatling).

## How it works

Even if the Jenkins plugin was built with the Maven plugin in mind, using it is not mandatory to be able to archive reports and track your results with the Jenkins plugin.

The Jenkins plugin looks into your job's workspace for any simulation report it can find, and archives only reports that hasn't been archived yet (meaning that you don't need to clean your workspace to delete previous reports).

As long as you are able to configure a job that will launch Gatling, execute a simulation and generate a report in your job's workspace (using the Maven plugin, sbt, a shell script or whatever), you're good to go!

However, note that the Jenkins plugin relies on the report folder's naming convention *runname-rundate* (ex: mysimulation-201305132230). You must not change the report folder's name in order to get the Jenkins plugin to work.

## Using Jenkins with Gatling Enterprise

[Gatling Enterprise](https://gatling.io/products/) has a dedicated Jenkins plugin.
This plugin can launch a Gatling Enterprise simulation and display live metrics.

Please refer to the [Jenkins Enterprise Plugin documentation]({{< ref "./enterprise" >}}).
