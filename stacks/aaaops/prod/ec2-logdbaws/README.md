This stack is defunct as of mid-Feb 2024. It is left here as a reference or if the stack gets resurrected. Mostly this stack just sets up an EC2 VM to do our own Elasticsearch setup in AWS (Opensearch was not suitable). The config of Elasticsearch itself within the VM is in Ansible

The associated 'logproxyaws' stack will not be destroyed, but the VM will be manually turned off to save $$. In the future if the network link between AWS + on-prem is fixed, the logproxy will be needed to ship logs to the on-prem Elasticsearch


----------

This node is to supply the Elasticsearch database for the EFK logging stack in AWS.

Sending logs across the VPN to the on-prem AAA network is the best answer, but the site-to-site VPN is massively unreliable and we will lose logs (and it'd down > 50% of the time)

We also tried the AWS service that is a fork of Elasticsearch, called Opensearch, and it's enough different from Elasticsearch to be a new product to 'have to know'

So to be consistent with the Elasticsearch we already have, we're running our own setup.

