# Continous Deployment with Terraform and Nomad
This post explores how to use the Nomad Terraform provider to run jobs with Nomad.  If you do not already have a Nomad server running, you can use the configuration from our post on [Auto bootstrapping Nomad](https://www.hashicorp.com/blog/auto-bootstrapping-a-nomad-cluster/) or you can use the playground at [https://katacoda.com/hashicorp/scenarios/playground](https://katacoda.com/hashicorp/scenarios/playground)

You can find the source code associated with this article at the following link:
[https://github.com/hashicorp/terraform-container-deploy-nomad.git](https://github.com/hashicorp/terraform-container-deploy-nomad.git)

## Nomad Terraform provider
The Nomad Terraform provider is very simple to use, like all Terraform providers we need first to configure the provider block.

```hcl
provider "nomad" {
  address = "https://your.nomad.server:4646"
}
```

The provider has no required arguments, but normally you want to set the `address` to the Nomad server to execute the job.  Other options for the provider including setting the region and the certificates for encrypted communications are also available.

[https://www.terraform.io/docs/providers/nomad/index.html](https://www.terraform.io/docs/providers/nomad/index.html)

Next, we need to configure the `nomad_job` resource:

```hcl
resource "nomad_job" "http-echo" {
  jobspec = "${data.template_file.job.rendered}"
}
```

The `jobspec` attribute contains the text for our Nomad job,  in this example, we are using a template as we need to use a dynamic value for the version of the Docker container `hashicorp/http-echo:${version}`.

```hcl
job "http-echo" {
    # ...

    task "http-echo" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:${version}"

        args = [
          "-text", "'hello world'",
          "-listen", ":8080",
        ]

        port_map {
          http = 8080
        }
      }

```

To pass dynamic variables to our Nomad job such as the tag for the Docker container we would like to run we can use the `data_template` feature of Terraform.

```
data "template_file" "job" {
  template = "${file("${path.module}/http-echo.hcl.tmpl")}"

  vars {
    version = "${var.version}"
  }
}
```

Putting this together we have the simple Terraform configuration shown in the example below:

```hcl
# Configure the Nomad provider
provider "nomad" {
  address = "http://localhost:4646"
}

variable "version" {
  default = "latest"
}

data "template_file" "job" {
  template = "${file("./http-echo.hcl.tmpl")}"

  vars {
    version = "${var.version}"
  }
}

# Register a job
resource "nomad_job" "http-echo" {
  jobspec = "${data.template_file.job.rendered}"
}
```


## Running a job
To run our job, we first need to see initialize Terraform:

```bash
$ terraform init
```

Then to see the changes that Terraform makes we can run the plan command:

```bash
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.template_file.job: Refreshing state...
The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ nomad_job.http-echo
    deregister_on_destroy:   "true"
    deregister_on_id_change: "true"
    jobspec:                 "job \"http_test\" {\n  datacenters = [\"dc1\"]\n  type        = \"service\"\n\n  update {\n    stagger      = \"10s\"\n    max_parallel = 1\n  }\n\n  group \"web\" {\n    constraint {\n      distinct_hosts = true\n    }\n\n    restart {\n      attempts = 10\n      interval = \"5m\"\n      delay    = \"25s\"\n      mode     = \"delay\"\n    }\n\n    task \"http-echo\" {\n      driver = \"docker\"\n\n      config {\n        image = \"hashicorp/http-echo:latest\"\n\n        args = [\n          \"-text\",\n          \"'hello world'\",\n          \"-listen\",\n          \":8080\",\n        ]\n\n        port_map {\n          http = 8080\n        }\n      }\n\n      resources {\n        cpu    = 500 # 500 MHz\n        memory = 256 # 256MB\n\n        network {\n          mbits = 10\n\n          port \"http\" {\n            static = 8080\n          }\n        }\n      }\n\n      service {\n        name = \"http-echo\"\n\n        port = \"http\"\n\n        check {\n          name     = \"alive\"\n          type     = \"http\"\n          interval = \"10s\"\n          timeout  = \"2s\"\n          path     = \"/\"\n        }\n      }\n    }\n  }\n}\n"


Plan: 1 to add, 0 to change, 0 to destroy.
```

Finally, to apply the changes, and start our job we run:

```bash
$ terraform apply -var “version=latest”
data.template_file.job: Refreshing state...
nomad_job.http-echo: Creating...
# ...

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The job is now be running on the Nomad cluster we can use the `nomad status http-echo` command to see the full status.

```bash
$ nomad status http-echo
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
web         0       0         1        0       1         0

Latest Deployment
ID          = d3c25fa9
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group  Desired  Placed  Healthy  Unhealthy
web         1        1       1        0

Allocations
ID        Node ID   Task Group  Version  Desired  Status    Created At
14fd5760  5c51d218  web         2        run      running   08/03/17 13:44:53 UTC
56693bc4  5c51d218  web         0        stop     complete  08/03/17 13:35:27 UTC
```

## Stopping a job
Stopping a job is just as simple if you run the command:

```
$ terraform destroy
Resources shown in red will be destroyed.

  - nomad_job.http-echo

  - data.template_file.job


Do you really want to destroy?
  Terraform will delete all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

nomad_job.http-echo: Destroying... (ID: http_test)
nomad_job.http-echo: Destruction complete
data.template_file.job: Destroying... (ID: 7c0afc8af326eaf9e2c6041df059d419f32f75b42b297f19a43c911bd5c80a14)
data.template_file.job: Destruction complete

Destroy complete! Resources: 2 destroyed.
```


## Conclusion
This post shows how easy it is to deploy Nomad applications using Terraform, and we hope you can see how this could be applied to your continuous delivery workflow.  These features are not limited to Nomad, Terraform also supports other schedulers like Kubernetes and Docker Swarm!
