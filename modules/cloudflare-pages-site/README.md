Cloudflare Pages Site
=====================

Making a new static site with this module
-----------------------------------------

1. get your github repo in order and figure out the build commands
    * if you have external developers, invite them to the git repo
2. copy an existing static site config and update the locals/config block
3. if you want to run a newer version of NodeJS than v12, add `NODE_VERSION=XX` as an env var
    * this is added in the `pages_deployment_preview_configs` variable
4. if you want an s3-based cdn, 'enable' that and add some users
5. manually add the DNS entry for the main site
    * this is not handled by terraform as often we won't control the DNS
    * the CDN's domain name is installed by this module


Configuration
-------------

```
locals {
  pages_site_config = {
    name = "client1"                   # namespace used for several things
  }

  pages_build_config = {
    build_command   = "jekyll build"   # the build command run by the Cloudflare Pages build worker
    destination_dir = "_site"          # the directory for Cloudflare Pages to copy the content after build
  }

  pages_source_config = {
    owner             = "YourGithubOrgNameHere"     # the Github Org name - Cloudflare must have a Github connection already made
    repo_name         = "GitRepoName"               # name of the git repo on Github
    production_branch = "prod"                      # which branch deploys to prod
  }

  s3_assets_config = {
    s3_create_assets_bucket = true                   # required if you want an assets bucket for images/large files
    s3_iam_users = [
      "johnsmith",                         # list of users. please use firstname-lastname so we can identify them
      "maewest"                                      # these IAM users have no keys, which must be manually generated and issued
    ]                                                # these IAM users only have access to this assets bucket
  }

  # main website domain. the assets bucket domain is set elsewhere
  domains = [
    "client1.aaa.tools",                              # list of front-end domains - these are 'custom domains' in Cloudflare Pages
  ]

  #cost_centre = var.cost_centre
  cost_centre = "client1"                             # tag gets applied to AWS resources
}
```

There's a couple of extra vars in the module variables.tf, but it's unlikely you'll need those

Gotchas
-------

* Every plan/apply, the Cloudflare 'deployment configs' will look like they're being destroyed. Ignore that.
    * This is presumably due to the wildcards "include/exclude preview" lines
        * Commenting out these lines does not remove the associated config and you continue to get the misleading lines

Preflight setup
---------------

* There must be a Github repo with something buildable in it
* The Cloudflare account must be connected to the Github org with the repo
    * this only needs to be done once for the account, not for each Pages site

Post-install actions
--------------------

* Create the formal domain name in DNS for the Pages site
* If you have created S3 read/write users, generate AWS keys for them manually and distribute to the users
* Add any external collaborators to the Github repo

What this module creates
------------------------

* Cloudflare Pages site
* Optional S3 assets bucket
* Optional S3 read/write users for bucket
* Cloudflare DNS record with proxy enabled
    * If Image Resizing is enabled for this DNS zone in Cloudflare, it will be available on the assets domain

What this module does not create
---------------------------------

* DNS record for the front-end website
    * you still need to provide a list of domains for the front-end to listen for
* IAM keys for the S3 users
* Anything in Github
* Enabling of the Cloudflare Image Resizing setting in Cloudflare for this domain
    * This is done in the domain/zone page, under 'Speed' in the sidebar
        * Speed > Optimization > flip slider and deselect 'from any origin'

Cloudflare Images Resizing
--------------------------

Cloudflare Image Resizing has been turned on for the `aaa.tools` domain. This gives automatic resizing if you follow a magic path:

* https://foo-cdn.aaa.tools/pic1.jpg     # the original image
* https://foo-cdn.aaa.tools/cdn-cgi/image/width=80/pic1.jpg     # image resized to 80px width

There are more options, see the docs: https://developers.cloudflare.com/images/image-resizing/url-format/

By default, the resized images are cached for an hour
