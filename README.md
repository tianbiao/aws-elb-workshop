AWS ELB Workshop
==========


Agenda
-------
1. Introduce Load Balancing and AWS ELB, slides here [AWS Elastic Load Balancing](https://docs.google.com/presentation/d/1rBEf3o24c-fb4jsHK2l4wWIothNpXGf_mh3szoCfJEk/edit#slide=id.p)

2. *Manually* Launch one EC2 instance without load balancing
	- AMI ID: `ami-005930c8f6eb929ba`
	- Docker images: `tianbiao/friendlyhello` 
	- EC2 instance launch script
	```
		#!/bin/bash
		docker pull tianbiao/friendlyhello
		docker run -d -p 4000:80 tianbiao/friendlyhello
	```
3. *Manually* Launch multiple EC2 instances with load balancing - AWS ALB 

4. *Automatically*  Use [Terraform](https://www.thoughtworks.com/radar/tools/terraform) to build the infrastucture *(we don't use cloudformation as [`Templating in YAML`](https://www.thoughtworks.com/radar/techniques/templating-in-yaml) has been marked as **Hold** in Tech Radar)*

5. Securing Web Applications with HTTPS


Terraform
--------
```bash
 cd infrastructure
 terraform apply
```