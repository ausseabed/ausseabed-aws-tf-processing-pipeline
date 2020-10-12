[![CircleCI](https://circleci.com/gh/ausseabed/ausseabed-aws-tf-processing-pipeline.svg?style=svg&circle-token=46ef01ebd72b56ec05a514c067d23655292ac5d8)](https://circleci.com/gh/ausseabed/ausseabed-aws-tf-processing-pipeline)

<!-- omit in toc -->
# Contents
- [Introduction](#introduction)
- [Continuous Delivery](#continuous-delivery)
  - [Build + Publish](#build--publish)
  - [Deploy](#deploy)

# Introduction
AusSeabed is a national seabed mapping coordination program. The program aims to serve the Australian community that relies on seabed data by coordinating collection efforts in Australian waters and improving data access. 

This repository contains AWS lambda modules and AWS step function that process bathymetry products. The terraform code for deploying the underlying infrastructure is housed in the https://github.com/ausseabed/ausseabed-aws-foundation/ repository.

# Continuous Delivery
The continuous integration server (CircleCI) compiles, publishes and deploys the Product Catalogue to the development environment. 
## Build + Publish
The CI server builds the lambdas and infrastructure and publishes them to non-production environment on any commit to master. 

## Deploy
The Step Functions use the latest version of lambda functions. So once, a lambda is deployed to AWS, it will be used in any new Step Function workflows.
```
git checkout master
git pull
git tag prod/deploy/0.1.1
git push origin prod/deploy/0.1.1
```