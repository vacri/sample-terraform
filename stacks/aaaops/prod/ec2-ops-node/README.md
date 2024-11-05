This 'ops node' is for ops to do "in AWS troubleshooting" without having to connect to ephemeral Fargate containers all the time. It uses half the stuff out of the 'jumphost' module, but is in the private subnets (you need to jump through the jumphost to ssh to it). It also has the AWS SSM agent installed, so you can connect that way.

There will be a base setup (common tools, users) in Ansible, but the server is intended to be for manual troubleshooting and users are free to install whatever on it

