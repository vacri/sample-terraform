Client9 static site
====================

The AAAClient site is a React static site on Cloudflare Pages, with static assets on s3

The Github repo is here: https://github.com/AAAFakeCompany/ThatClient

Note that this site does NOT have non-prod listed in Terraform - Cloudflare handles the dev channels, not Terraform, but the overall site is configured in Terraform

Note also that the DNS record for the domain name is not created by this module, as we don't yet manage DNS in Terraform
