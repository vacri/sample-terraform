Sample Terraform Stacks
=======================

This is an anonymised repo for a multi-account AWS setup, which was opensourced by a previous employer. The directory structure was largely based off a prior nascent-and-unused Terragrunt setup they had for Azure, but the file content is almost entirely written by yours truly. Terragrunt was not used in this setup because it's massive overkill for a small shop and basically means configuring everything twice.

Features:

* Originally set up in 2023, using Terraform just before the OpenTofu fork happened
* This repo is designed generally as a collection of semi-independent stacks. Inheritence between stacks has intentionally been kept to a minimum (not completely absent though), with the following exceptions
    * The network/VPC stack gets inherited by pretty much everything, since they need to know where they 'live'
    * Docker services inherit the docker cluster (ECS) stack, for obvious reasons.
* Initial terraform bootstrapping is done in Cloudformation, because it's fifteen times easier. Terraform can bootstrap itself (creating statefile buckets and lock databases for the terraform engine) but it's complex and silly to do.
* The original company names have been changed to 'aaa' (main company) 'aaaops' (sysadmin + common services account separated out), and 'bbb' (sister company, but didn't get time to develop for this)
    * There's been a lot of find/replace for various strings, namespaces, id numbers. This has likely broken logic workflow somewhere, but shouldn't be too hard to find and fix
    * Client projects originally had meaningful namespaces instead of "client1"
* The individual stacks/modules are fairly vanilla and straightforward Terraform, with one significant exception
    * The 'fargate-web-app' module is overly complex, but it works. I wanted to create a generic docker service with an optional s3 bucket and 1-3 optional NFS mounts (req'd for supporting legacy apps) - having a single module means avoiding drift from having static variants in different files
        * The issue is that the docker service in Fargate is defined in a jsonencode call, which blocks nesting of various dynamic terraform commands inside - so various hax were required to make it work. Comments in the file describe what and why
* Some items are not covered by terraform - these are usually mentioned in various ReadMes and why. Generally these are for small one-off configs for the entire account (no point in automating) or for things that don't have good terraform integration (eg: DNS-managed certs on AWS when DNS is elsewhere)
* The makefile is a convenience tool and generally does some preflight checks for each run. Worth using
    * `make` will give you usage info
    * The makefile requires several env vars to be set - see the info below
* Resources generally default to the smaller end of things, to save $$$
* IAM profiles get generated separately for almost every item, to reduce 'blast radius'
* There was a toy chatgpt enquiry module in terraform. I implemented so you could ask questions with this makefile, but the source module was broken last I tried.



Original readme is listed below. Images are mostly absent as they held identifying info. "OU" refers to the AWS Organisational Unit, and there are generally separate AWS accounts for each OU+environment combination (non-prod gets smushed together under 'dev').




Terraform
=========

Usage
-----

We're using a directory structure that requires use of Organisational Unit (`aaa`/`bbb`/etc), Env (`prod`/`stag`/`uat`/`dev`/`qa`/whatever), and Stack (name of thing being deployed).

Essentially this git repo is a series of mostly independent mini-stacks in directories arranged by OU and Env. Some stacks depend on other stacks for networking information (subnets, etc) but apart from this, they're generally independent of each other.

```bash
make help

make env   # shows you the current values for ou, env, stack

# any time you change the backend or make structural changes to the stack, init needs to be rerun
# 'init-reconfigure' is also available in case it asks you to do that
make init ou=aaa env=dev stack=ops-buckets

# or you can use exported env vars
export ou=aaa
export env=dev
export stack=ops-buckets
make plan

make deploy

make destroy

# reformats the files in the target working directory to match golang patterns
make fmt
```

I keep my env vars in `~/.tf/env` so I can source them to 'prep' a terminal

```bash

. ~/.tf/env

export ou=aaa env=dev stack=ops-buckets
make plan
make apply
```

Gotchas
-------

* The `ou` for the AWS account named 'sharedservices' is `aaaops` in Terraform
    * This is because 'ss', 'shared', 'sharedservices' are all taken in global namespaces (s3), and 'aaashared' is a little misleading. Generally only ops will be done in that account, so `aaaops` kinda fits, though not perfectly
* Cloudflare Pages sites only have a presence in `prod` envs in Terraform
    * Cloudflare itself handles the dev branches, so separate config for dev is not required in Terraform
* Sometimes TF throws an error on instantiation of a complex module (eg `aws-vpc`), because a `for_each` relies on a dynamic resource that hasn't been generated yet
    * the official way to deal with this is to use `-target` to generate the depended-on resource first
    * I just comment out the offending stanza (in `aws-vpc`, the s3 endpoint route table IDs) for the first run, then uncomment and re-run
    * UPDATE: looks like the issue is because it's recommended to use `for_each=toset()`, but this is bad
        * instead, create a map/dict: `for_each = {for key, val in aws_efs_file_system.efs_volume: key => val}`
        * the above line created a map of objects with the particular data it was given, and I can then refer to their attributes like so: `each.value.id` for the .id

### Backend file workaround

Terraform *cannot* interpolate vars in the `backend` code block. This means that we can't have dynamically-assigned s3 keys/files to use for state - as in, we can't have a generic 'backend' config block which uses variables to figure out the path to the statefile.

There are lots of different and gnarly workarounds to this problem, so I've gone with a 'pre-script' approach. The makefile calls some preflight safety checks, and one of these calls a script that checks for a backend.tf file. If it doesn't exist or the content is 'wrong', a new backend.tf is put in place and it has a key based on the file path, so it should be unique. This should ensure that the statefiles on s3 don't conflict with each other.


Managing Terraform state
------------------------

### Importing existing resources

The makefile can be used to wrap the terraform import. Terraform import needs a resource reference and the ID for the pre-existing resource that is to be imported.

The resource name is the resource_type.resource_name. If you're importing a resource for a submodule, you need to prepend 'module' and the name of the module.

```
# the following command imports a resource defined by:
# * a submodule
# * which we've called 'aws-account-misc' in main.tf
# * the resource in the submodule of type 'aws_iam_service_linked_role'
# * which we've called 'ecs_service_linked_role' in the submodule's main.tf
# the resource to be imported, for this kind of resource, is the ARN
# (in this case, account specific due to the account ID in the middle)

# we have already set the vars for ou, env, stack
make import \
    resource=module.aws-account-misc.aws_iam_service_linked_role.ecs_service_linked_role \
    id=arn:aws:iam::123456789012:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS
```

One example of a resource to be imported is the ECS Service Linked Role in AWS. Once created, it can't be destroyed, and there's only one of them. I removed the Cloudformation template but the Role was not destroyed - so I need to import the existing role into the TF stack that now manages(well, intialises) this resource)

### Renaming existing resources

The makefile can be used to rename resources. In the example below, I hadn't updated the PoC name for the ops buckets module, and wanted to rename it in the resource stack

```
# change the module name here and save
vi PATH/TO/main.tf

# need to run an init to set up the new name in the statefile
make init

# change the name in the statefile (calls 'terraform state mv blah1 blah2')
make mv from=module.s3-bucket-test to=module.s3-ops-buckets

# confirm the stack matches the new setup
make plan
```

----

User workstation setup
======================

You need Terraform installed, and a \*nix environment (filesystem paths, script tools)

Apart from that, you need a terminal and auth for the provider you're using. For AWS, this is your SSO user who must be using the AdministratorAccess role, and then you copy out the env vars for that SSO login into the terminal

### Terraform

Installation instructions here: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### SSO User

You need to have a user made in Active Directory first (for Auth), then a user made in AWS (requires an AWS admin). You will already have an AD user as a staffer at AAA.

Once you have your AWS SSO user, you can log into the aws console at https://aaa.awsapps.com/start#/ or https://aws.aaa.com.au

On the AWS web console, you can find the env vars to auth your terminal by selecting the 'management account' and then selecting the 'command line or programmatic access' link. A dialogue box will open up with several different methods for copying auth keys. Option 1 can just be cut/pasted into a terminal and will auth just that terminal. Option 2 needs to be copied into your AWS config file, but will auth all AWS tools (cli or otherwise). These keys are valid for only 6 hours before they expire and are rotated

### Sourcing API keys via env

To avoid saving secrets in the repo or similar, we'll use per-user secrets supplied via env var. Basically a file of env vars that you source before calling Make.

Env vars prefixed with `TF_VAR_` are then available to Terraform modules to use directly.

```
$ cat ~/.tf/env
export TF_VAR_cloudflare_api_token=mycloudflareapitokenhashstring
export TF_VAR_github_token=mygithubapitokenhashstring
export TF_VAR_chatgpt_api_key=mychatgptapikey
```

Then I just source this file to prep a shell, before running make on something that requires those auth items
```
. ~/.tf/env
```

Our AWS keys can go in this file, but generally not worth it as they are so short-lived (6 hours); I just apply them directly to my terminal.

----

Tokens
------

### Fetching Your AWS Tokens

You need to be in the Administrators SSO group to be able to access the Terraform deploy roles in the client AWS accounts. To authorise your terminal with AWS credentials, log into the AWS SSO console at https://aaa.awsapps.com/start/ or https://aws.aaa.com.au

These tokens are valid for 6 hours. Copy the tokens out of 'option 1' to paste directly into your terminal (supports just that terminal), or use the tokens in 'option 2' to paste into your `~/.aws/credentials` file (supports all terminals/tools)


![aws token retrieval 1](docs/aws-tokens-1.png)

![aws token retrieval 2](docs/aws-tokens-2.png)

### Generating your Cloudflare API Token

At time of writing, we need a Cloudflare token with Pages edit rights, and likely will need DNS edit rights in future.

The API token you generate can only be viewed once, so you need to save it off somewhere. I put it into `~/.tf/env` in the format `CLOUDFLARE_API_TOKEN=[token]` so I can just source this file and be done with it. If you lose the token, you can just regen it in your Cloudflare console.

You will need to make a "custom API" token, as the premade suggestions don't support Pages.

![cloudflare token generation](docs/cloudflare-api-token.png)

```bash
# token test, will reply if valid or invalid
. ~/.tf/env     # if you've saved the token to this file, source it to your env

curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type:application/json"
```

Permissions required (at least):

* Account/Cloudflare Pages
* Zone/Page Rules
* Zone/DNS

### Generating your Github Token

At time of writing, we don't have github repos managed in Terraform, but in case we one day do, this is how you get the token.

Github has two forms of API token, 'classic' and 'fine grained' (in beta). We use the Classic form here. API access via token had to be turned on at the account level, which is done on the Org admin web console under `Personal access tokens` > `Settings` and has already been done

To generate your own access token for Github, navigate to https://github.com/settings/tokens and select Generate Token. Either style should work, but we'll show Classic style here

Give your token a name, and select the scopes required - you will probably need full `repo`, `workflow`, `admin:repo_hook`, and maaaaybe `delete_repo`, though we need to be careful about destroying repos programmatically. May as well select an appropriate expiry as well.

On the next page you'll be shown the API key, which you won't see ever again. Save it off to a file you can source for env vars (above)

![github token generation](docs/github-api-token.png)

### Generating your ChatGPT Token

Set up a personal ChatGPT account and navigate to https://platform.openai.com/account/api-keys - it's fairly straight-forward.

The token then needs to be made available to Terraform by using the `TF_VAR_chatgpt_api_key` env var - this can go in the same env file as the Cloudflare token.

----

Terraform Infrastructure/Remote State Setup
===========================================

Before terraform can be used, the cloud environment needs to have some preliminary work set up. At time of writing, the work below has already been done.

### AWS

#### Statefile bucket

The system uses a shared statefile on S3. There is an s3 bucket template in `cloudformation/s3/` to create this bucket. It should be created in the AWS management account. Only this one bucket is needed - subaccounts (or other vendors) do not need their own bucket.

#### Statefile lock

There is a DynamoDB table to provide a statefile lock when a user is making an edit, to prevent conflicts when another user is deploying. It's created by the s3 cloudformation template above.

Both the s3 bucket content and dynamo table content are accessable by SSO superadmins, since they can access everything.

#### Client account IAM Roles for deploying in AWS

Ensure you have the terraform deploy user set up in each *client* account. There's a template in `cloudformation/iam` for this purpose. The management account does not need this user made. When the user authorises their terminal with their AWS keys, they are using an IAM Role that is allowed to 'assume' these client account IAM Roles.

This IAM Role is created with the Cloudformation templates in `cloudformation`. You can create these preflight resources in TF itself, but the workflow is silly and tedious.

#### SSO users on AWS management account

This setup has been designed for an SSO user with admin privs on the management account to deploy to all AWS client accounts. The client accounts use a "terraform-deploy" role that is assumed by an admin user in the management account.

If your user has multiple logins in the AWS SSO console, only the one marked Administrator should work (a bug if not). At time of writing, no-one has multiple logins.

### Auth for non-AWS SaaS

Will depend on the SaaS in question. For preference, it will chain off the AWS management account as that way we can control auth with SSO, but some SaaSes may require other methods.

Auth for other SaaSes is only required if running a stack that deploys to that specific SaaS

Troubleshooting the auth chain
------------------------------

There's quite a complex auth structure going on. The system is made to be pain-free day-to-day, but when something goes wrong, it's complex to understand. This section describes the parts involved in accessing the various parts of the auth system

You can check your auth if you do a terraform 'plan' step. This won't make any alterations to the infra, but it does exerice the auth process.

### Active Directory user

The user needs to be in AAA's AD setup. No particular group is needed - that is defined in AWS SSO/IAM Identity Centre. If you can log into your AWS SSO console, then AD is working for you and you have had your AWS SSO user set up

### AWS SSO/IAM Identity Centre user

AWS users are set up in the management account in the IAM Identity Centre. The permissions between users and accounts is also set up here, and beyond the scope of this document. However, in order to use the Terraform setup in this repo, the user must have a role that gives them AdministratorAccess on the *management account*. The client account roles (below) will be configured to only allow 'admin' users that are currently assuming that specific role.

Note that SSO Permissions Sets are not relevant here - the client account permits users in the management account to assume the TF Role as long as they're logged in as an admin, regardless of Permissions Set.

### AWS Client Account Roles

These Roles are full-admin IAM Roles and allow anything to be deployed/destroyed in the account. They are deployed with the CF templates in `cloudformation/iam/`. These Roles are configured to allow users from the management account to 'assume' them.

Possible problems here are a mismatch between the client account Role's permitted Principal (user) + Conditions versus the SSO role making the call. You can log into the AWS Web Console with your SSO user and check the Terraform Role directly (it doesn't affect web console access)

If you want to see what your current identity is in AWS, it's your 'caller identity' and you can check it with STS on the aws cli tool, shown below. The ARN in the caller identity relates to the permitted users in the client account Role. That ARN must be allowed in the client Role

```
$ aws sts get-caller-identity
{
    "UserId": "AROAXSKAKJHDSKLAG:johnsmith@aaa.com.au",
    "Account": "5432109876",
    "Arn": "arn:aws:sts::5432109876:assumed-role/AWSReservedSSO_AdministratorAccess_83a886d9783b6ed5/johnsmith@aaa.com.au"
}
```

The client account role used to deploy a stack is defined by the `assume_role` directive in the AWS `provider` block in each `main.tf` file

```
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform-deploy-superadmin"
  }
```

### Cloudflare API Tokens

These are pretty straight-forward - your API token gives you whatever perms your Cloudflare user has. Auth problems here are going to be the usual problems like an incorrect key or the user not having the correct perms for their account.

----

Toys
====

ChatGPT
-------

ChatGPT has been added to the makefile, so you can ask questions. You need to have a chatgpt api key in your env. It has been used this to solve some technical issues, so it's not completely inappropriate.

Tokens are generated here: https://platform.openai.com/account/api-keys

```
export TF_VAR_chatgpt_api_key=blahblahblah
make ai-init # one time only

make ai q="what should I have for lunch?"
```

The ChatGPT stack is in `aaaops/dev`, but is not otherwise connected to any of the other stacks and does not use remote state on s3 - it's independent of the rest of the stacks.


Training Tasks
==============

Things to do beyond 'hello world' stuff, to practice terraform while adding something useful

Site-to-site VPN
----------------

* need to add a VPN endpoint to the VPCs
    * this will include adding routes to route tables (see `aws-vpc-peering` for some examples)
* need to switch on whatever else needs switching on in AWS
* need to grab info from the network site to get the VPN matched up at both ends
    * I'm not actually sure what's required

AWS Certificate generation workflow
-----------------------------------

ACM certs need DNS entries. Our DNS entries are in Cloudflare. Figure out the workflow to get an ACM cert automatically generated for one of our domains in Cloudflare

basic workflow, taken from fargate-cluster-shared readme in templates/:
1. request an ACM cert for a domain name in our control
2. get the CNAME entries for the pending cert
3. apply those entries to cloudflare DNS
    * have a mechanism that doesn't cause issues if the entry already exists but isn't under control of this stack
        * this happens if someone has already made an ACM cert for a given domain on the AWS account
4. wait for the ACM cert to 'issue'
5. continue on with the rest of the stack

We need to have certs good-to-go to instantiate HTTPS listeners on loadbalancers

Cloudflare Pages s3 bucket name rework
--------------------------------------

The cloudflare-pages module currently names the s3 bucket with dots in it. This allows s3 to respond to requests by its FQDN, but the drawback is that it cant use HTTPS as the s3 wildcard certificate can't cover it. In its current form, this allows us to have a pretty name for the s3 website, but this is not really necessary.

The problem comes when we proxy the site via Cloudflare (traffic is free; image resizing support; s3 direct webistes are slow; other reasons). The entire zone has to default to either http or https on the backend, and the Cloudflare proxies *do not* follow redirects. We default the zone to https, but need to put an http exception rule in for these s3 buckets (at time of writing, Client9 and Client1). The Cloudflare API does not support individual rules - the entire rules block appears to be a single API call, which means if we configure a second rule, it will overwrite the first rule block.

Whichever way we go, we need to add a *manual* rule if we proxy through Cloudflare to an s3 bucket. One of:

* http override for a given hostname (ie: don't use the default https)
* change `Host:` header for the backend request
    * so that a request to foo-cdn.aaa.tools goes to foo-cdn.s3.amazonaws.blah on the backend

For static sites, it's not the end of the world to have an http override, but then we can't claim end-to-end encryption (minor security tickbox).

This task is to change the name of the bucket in the cloudflare pages module so that it doesn't have dots in it. It still needs to support the existing stacks' dotted bucket names since we can't rename those buckets (maybe have a variable to override automatic naming?)

This is a low impact modification - either way, we still need to add a manual rule


Merge .terraform directories
----------------------------

Each stack is an independent standalone terraform stack (minor dependencies). Each of them puts the .terraform directory in the same relative location, and the AWS provider is pretty large (300+MB). Each stack pulls its own copy on init, and these add up. While these locations are .gitignored, they still take up a *lot* of space on disk - at time of writing, this repo is 16GB on my localmachine, almost entirely in these .terraform provider dirs

The task here is to make a single `.terraform` directory and symlink all the individual stacks to reference it. Obviously it needs to be .gitignored.

The symlink should be checked/created by the sanity-check script that also writes the backend file for each stack, `scripts/backend-writer`. This script gets called on `make init` and sets the correct backend settings, so may as well get it confirming/creating the symlink as well

1. create a .terraform/ dir in the base of the repo
    * the sanity-check script should check that this dir exists and create it if missing
    * this location must be .gitignored
2. switch out all the stacks' .terraform directories with the symlinks and confirm works
    * we don't need to commit these new symlinks - the sanity-checking script will create them if missing
3. test a few stacks with `make init`, which populates the `.terraform` directory
    * if the stack already has a lockfile, the correct version of the provider should be installed
    * most stacks could probably be updated to latest provider anyway (ie: remove lockfile and let it be remade)


