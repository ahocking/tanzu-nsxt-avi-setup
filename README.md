# Terraform

This is a collection of Terraform plans that will execute the following tasks:

- Provision Jumpbox in lab environment 
- Configure existing NSX-T environment for TKG & NSX ALB 
- Configure NSX ALB (AVI) to integrate with NSX-T network segments

The `terraform-init.sh` file can be used to apply or destroy each Terraform directory. Each directory has additional information in the `README.md` file.
