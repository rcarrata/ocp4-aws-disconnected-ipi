## Deploy prerequisites for Private / Disconnected install

Terraform files for deploy the prerequisites for Disconnected / Private installation

### Install prerequisites

Export the AWS credentials for your account
```
export aws_access_key_id="xxx"
export aws_secret_access_key="yyy"
```

Execute the makefile for launch the terraform files
```
make all
```

### Tested

* Terraform 0.14
* AWS