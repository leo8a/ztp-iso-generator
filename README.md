# (Prototype) Minimal RHCOS ISO with pre-staging RootFS
Brief description goes here.

| :warning: **Prototype described in this repository is unsupported by Red Hat.** |
|---------------------------------------------------------------------------------|


## Current Installation workflows
Brief description goes here.

### Current boot workflow in RHCOS

> TODO

[//]: # (Add https://console.redhat.com/openshift/assisted-installer/clusters/)


## Proposed boot workflow (pre staging-based) for Minimal RHCOS
1) Ensure content within the RootFS partition doesn't get wiped out
   - How the RootFS partition becomes accessible to servers?

2) We would need to start a http server locally to serve up the image, I don't believe we can mount the file directly.

   a) check if the RootFS partition can be mounted (fixed disk name?)

   b) check if content within the RootFS partition can be copied via `rsync`

   c) check if content within the RootFS partition can be served via `httpd` server

4) Finish the initial boot using the local roofs.

[//]: # (TODO: Add reference to this case: https://access.redhat.com/solutions/5605431.)

## Validation
Compare current boot workflow vs pre staging-based for Minimal ISO.
- Show total booting times
- Show percentage of improvement between both approaches


### Other resources
- [ztp-iso-generator](https://github.com/redhat-ztp/ztp-iso-generator)
- [Installing CentOS and configuring GRUB](https://github.com/openshift/assisted-service/blob/master/docs/user-guide/boot-discovery-image-on-aws-ec2.md#installing-centos-and-configuring-grub)
