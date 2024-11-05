Client1 static site
====================

The Client1 site is a Jekyll static site on Cloudflare Pages

The Github repo is here: https://github.com/YourGithubOrgName/client1

Note that this site does NOT have non-prod listed in Terraform - Cloudflare handles the dev channels, not Terraform, but the overall site is configured in Terraform

Note also that the DNS record for the domain name is not created by this module, as we don't yet manage DNS in Terraform
