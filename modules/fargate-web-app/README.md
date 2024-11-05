Fargate Web App
===============


There's a lot going on in this module, so let's have a readme. Conceptually it's fairly simple, but there's a lot of details, providing a generic solution with flexibility.

This module is intended to provide a basic single-container application attached to a loadbalancer, with an optional s3 bucket for assets. Pretty typical containerised web app. It expects to use a pre-existing ECS cluster and loadbalancer, sharing the latter for cost-saving porpoises.


Container image/label/port and first run
----------------------------------------

There is a chicken-and-egg problem in this stack as it (optionally) creates an ECR repo and also a service that pulls an image from that ECR repo. As we can't really populate the repo in the same run as the service is created, we need to use a placeholder image until we can seed the ECR repo

Leave `container_image`, `container_label`, and `container_port` blank until the ECR repo is seeded with an appropriate image, then configure these settings and rerun Terraform

The default values for these vars give us a placeholder image of Apache (`httpd`/`latest`/`80`)

----

The parts of this module
========================

IAM Roles
---------

There are four IAM roles, three of which are used in ECS. We make new roles for every stack to allow us the ability to make some stacks have extra permissions.

The github actions role will need to be fished out and referenced in the github actions file. The other roles are ignorable unless you need to add more permissions.

* 'service' role
    * used by ECS when managing the service as a whole, attaching new containers to loadbalancers, etc
* 'task' role
    * given to the application running in the container itself. If the application is prohibited from doing something, this is the role to modify
* 'task execution' role
    * used by ECS when invoking container launches. I'm not sure what the philosophical separation is in comparison to the service role
* 'github actions' role
    * used by github actions to push images and update ECS services
    * we don't use a global role as some repos will have external developers who can modify the github actions commands
    * we have a separate stack for each individual eng (test/stag/prod) but only one github role is needed - we create this one in the stack that creates the ECR repo, since the role is used to push to the repo

ECR Repo
--------

There is a single global ECR repo that will hold containers for all environments for the application. As we have several stacks for a given app, one for each environment, only one of them should create the ECR repo. So there's a `create_ecr_repo` bool to flag whether or not a given stack should create the repo

The ECR repo name is not re-used in the container definition - this allows the stack to be temporarily flipped to a different container image as required.

ECS Service
-----------

An ECS service is basically a bunch of metadata that groups together one or more docker images and runs them as containers. This stack uses a single container, plus (TODO) some 'scheduled tasks' run from that container (=cronjobs)

This metadata is used by the underlying cluster to attach containers to various services and monitor the health and scaling of the containers

### ALB Target Group / Listener Rule

You attach a 'thing' to an AWS 'Application Load Balancer' by putting it into a 'target group', and then attaching that TG to a 'listener' (https) on the loadbalancer. Target Groups require being attached to an ALB before they work - the healthchecks in them are actually done by 'the ALB', not the 'Target Group' itself.

(as far as I can tell, a Target Group is basically an nginx snippet that is loaded onto a loadbalancer)

The Listener Rule attaches to the HTTPS listener on the loadbalancer, and is configured to listen for the hosts in the `host_headers` terraform var. `host_headers` is basically a list of domains you want this stack to listen for. An example of using multiple domains is when you have a temporary domain for the production site, and then add the 'real' domain later on.

#### HTTPS Certificates

These are not terraformed - you must manually attach a certificate from AWS Certificate Manager to the loadbalancer in question. All hosts in `host_headers` should be covered by an https certificate, but it doesn't need to be the same certificate

### Autoscaling configuration

Copied from a how-to online; not tested yet. In theory it should scale up/down the number of containers as you hit the cpu + mem targets

### ECS Service Security Group (firewall)

I'm not sure why this is on the Service rather than the Task, but basically it allows traffic into the containers

ECS Task
--------

ECS Tasks are the actual instantiation of the docker containers. There's a lot of config in here, but it's all around setting up which containers to run where. The Task describes an instance of the app, and the Service runs multiple instances as required.

Note that Task Definitions (and Services) for FARGATE container types have certain restrictions and are configured a little differently to vanilla ECS container types. Something to be aware of when lookig at AWS doco.

### S3 task.env file

I've set up the tasks so that a file on s3 is pulled by ECS and read in as environment variables. This file can be empty, but it *must* exist or the task will fail to launch. This allows us to have config-free containers (more portable) if the app inside can be configured with env vars

### Cloudwatch log group

While a Task Definition can auto-create a log group, it doesn't set an auto-expire time, so we create this as a separate resource

### Task Definition

The Task Definition contains all the data required to provide "one instance" of the application. The CPU and memory for FARGATE containers only comes in premade pairs - see the file comments in the variables file for more info

The `container_definitions` section is the meat of the Task Definition. In this stack, we're just defining a single container, but you can have multiple. The `container_definition` is in json, because frankly the terraform/HCL option for this item is crap and doesn't support everything... and is poorly documented. The content of the current `container_definition` is fairly straight-forward. At least one container must be marked 'essential' for a given Task, but the rest of the items are fairly obvious

### Scheduled Tasks (cronjobs) TODO

These are TODO and don't exist at time of writing

When you have an autoscaled service, you have multiple identical nodes. Which one runs the cronjob? This is what Scheduled Tasks is for - a single entity launched to run the job at that time and then exit

S3 Assets Bucket
----------------

A private s3 bucket can optionally be created, for those applications that need to store state in files (eg: document uploads, images, etc).

The bucket has versioning enabled, and will cycle out overwritten/deleted items after a couple of weeks

### DNS Record (TODO)

Automatically makes the domain(s) in `host_headers` if it matches with a zone we own in Cloudflare. Haven't quite sorted out the Terraform logic for this yet, see notes in the file
