## Deploy prerequisites for Private / Disconnected install

Terraform files for deploy the prerequisites for Disconnected / Private installation

<img align="center" width="950" src="pics/disconnected.png">

### Fill the variables tfvars

```bash
cp -pr configuration/tfvars/terraform.tfvars.example configuration/tfvars/terraform.tfvars
```

NOTE: fill the variables with the proper definitions

### Execute terraform for generate prerequisites

Export the AWS credentials for your account

```bash
export aws_access_key_id="xxx"
export aws_secret_access_key="yyy"
```

Execute the makefile for launch the terraform files

```bash
make all
```

### Tested

* Terraform 0.14
* AWS
* OCP <= 4.9.x
