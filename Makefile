

stack_name := $(ou)-$(env)-$(stack)
stack_dir := stacks/$(ou)/$(env)/$(stack)

.PHONY: all
all: help

.PHONY: env
env: ## print out the current 'module settings'/stack in use
	@echo "   ou=$(ou)"
	@echo "  env=$(env)"
	@echo "stack=$(stack)"

##
## Basic workflow
##


.PHONY: init
init: preflight-checks   ## pulls down TF libraries and sets up a working environment as befits main.tf
	terraform -chdir="$(stack_dir)" init

.PHONY: init-reconfigure
init-reconfigure: preflight-checks   ## incorporates changes to working environment due to certain changes in main.tf
	terraform -chdir="$(stack_dir)" init -reconfigure

.PHONY: validate
## example ## make validate
validate: preflight-checks   ## local workflow/syntax check, doesn't hit remote state or APIs
	terraform -chdir="$(stack_dir)" validate

.PHONY: plan
## example ## make plan
plan: preflight-checks    ## plan and print out what would change if an 'apply' is run
	terraform -chdir="$(stack_dir)" plan

.PHONY: apply
## example ## make apply
apply: preflight-checks    ## apply changes to stack
	terraform -chdir="$(stack_dir)" apply

.PHONY: plan-destroy
plan-destroy: preflight-checks    ## plan and print out what would change if a 'destroy' is run
	@echo "\033[93;1mIf you get a protected resource error (eg: task.env), remove it from the state file with 'make rm resource=[ID]' and re-run the destroy. Use 'make import ...' if you apply a new stack to bring in the existing resource, otherwise TF will overwrite/create again\033[0m"
	terraform -chdir="$(stack_dir)" plan -destroy

.PHONY: apply-destroy
	@echo "\033[93;1mIf you get a protected resource error (eg: task.env), remove it from the state file with 'make rm resource=[ID]' and re-run the destroy. Use 'make import ...' if you apply a new stack to bring in the resource, otherwise TF will overwrite/create again\033[0m"
apply-destroy: preflight-checks    ## destroy items in stack
	terraform -chdir="$(stack_dir)" apply -destroy

.PHONY: output
output: preflight-checks ## lists outputs for stack
	terraform -chdir="$(stack_dir)" output

##
## Copying stuff around
##


.PHONY: skel
## example ## make skel ## (autopopulates if it finds a template with the same name as stack)
skel: check-vars    ## create initial skeleton when making a new stack for deploy
	@if [ -d $(stack_dir) ]; then echo "Module dir $(stack_dir) already exists, aborting skel"; exit 9; fi
	$(info creating skeleton in $(stack_dir)...)
	@mkdir -p $(stack_dir)
	@cd $(stack_dir) && ln -sf ../common-vars.tf .;
	@scripts/backend-writer go
	@stack_dir=$(stack_dir) scripts/template-copy go

.PHONY: template
## example ## make template t=fargate-web-app ## (where 't' is in templates/stacks/)
template: check-vars
	@if [ -d $(stack_dir) ]; then echo "Module dir $(stack_dir) already exists, aborting template"; exit 10; fi
	@if [ -z $(t) ]; then echo "No template specified, aborting.\nUsage: make template t=[TEMPLATE]"; exit 11; fi
	@if [ ! -d templates/stacks/$(t) ]; then echo "Template dir '$(t)' not found, aborting template"; exit 12; fi
	$(info copying template 'templates/stacks/$(t)' to '$(stack_dir)'...)
	@mkdir -p $(stack_dir)
	@cd $(stack_dir) && ln -sf ../common-vars.tf .;
	@scripts/backend-writer go
	@rsync -a templates/stacks/$(t)/ $(stack_dir)



.PHONY: import
# example of this target (too long for help text)
# make import \
#     resource=module.aws-account-misc.aws_iam_service_linked_role.ecs_service_linked_role \
#     id=arn:aws:iam::997358959085:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS
## example ## make import resource=[TF reference] id=[resource id] ## (see makefile comments for full example)
import: preflight-checks   ## import existing infrastructure into resources managed by stack
	# for some reason I couldn't get the unset var check working properly with makefile ifndef, so using a shell test instead
	@test "$(resource)" && test "$(id)" || (echo "ERROR: resource/id not set, aborting.\n Usage: make import resource=module.module_name.resource_type.resource_name id=id_to_import"; exit 6)
	terraform -chdir="$(stack_dir)" import $(resource) $(id)

.PHONY: mv
## example ## make mv from=module.s3-bucket-test to=module.s3-ops-buckets ## (eg after renaming a submodule reference)
# also, can be weird with quotes, eg:
#    from='module.fargate_web_app_with_efs.aws_efs_backup_policy.efs_backup[\"fs-0cb204f1265c4ffce\"]'
mv: preflight-checks   ## rename a resource within the stack, used if renaming a resource's codename
	@test "$(from)" && test "$(to)" || (echo "ERROR: from/to not set, aborting.\n Usage: make import from=module.oldname to=module.newname # or resource or whatever"; exit 7)
	terraform -chdir="$(stack_dir)" state mv $(from) $(to)

.PHONY: rm
## example ## make rm resource=aws_s3_object.task_env
rm: preflight-checks ## remove a resource from Terraform's statefile, useful for protecting items before a destroy
	@test "$(resource)" || (echo "ERROR: set a resource to remove ['resource=blah.blah']"; exit 18)
	terraform -chdir="$(stack_dir)" state rm "$(resource)"

##
## Code cleaning
##

.PHONY: fmt format
format: fmt
fmt: preflight-checks    ## format files to golang standards
	@terraform -chdir="$(stack_dir)" fmt

# TODO: linting

##
## Terraform interrogation
##

.PHONY: list
## example ## make list
list: preflight-checks    ## list resources managed by stack
	@terraform -chdir="$(stack_dir)" state list

.PHONY: show
## example ## make show resource='module.vpc_peering[\"aaadev\"].data.terraform_remote_state.owner' ## (get the resource ref from 'list', quotes are finicky)
show: preflight-checks    ## show detail of a resource managed by stack
	@test "$(resource)" || (echo "ERROR: 'resource' not set, aborting.\n Usage: make show resource=module.module_name.resource_type.resource_name"; exit 11)
	@terraform -chdir="$(stack_dir)" state show $(resource)

.PHONY: console
console: preflight-checks
	@echo "module vars cannot be viewed, only module outputs (try 'make show' for that)"
	@terraform -chdir="$(stack_dir)" console

.PHONY: refresh
refresh: preflight-checks
	terraform -chdir="$(stack_dir)" refresh

.PHONY: force-unlock
## example ## make force-unlock id=0f9ff376-ab2d-d6bb-05c5-40c3be00d36d ## (get id from error message)
force-unlock: preflight-checks
	@test "$(id)" || (echo "ERROR: 'id' not set, aborting.\n Usage:  make force-unlock id=ID_FROM_ERROR_MESSAGE"; exit 12)
	@terraform -chdir="$(stack_dir)" force-unlock $(id)

##
## Toys
##

.PHONY: whomai
whoami:
	@aws sts get-caller-identity

.PHONY: ai-init
ai-init:
	@terraform -chdir=stacks/aaaops/dev/chatgpt init

.PHONY: ai
# needs your chatgpt key in TF_VAR_chatgpt_api_key
# https://platform.openai.com/account/api-keys
# the sed cuts out all lines before 'Outputs', so there's less visual spam. Not perfect, but enough
ai:
	@test "$q" || (echo Usage: 'make ai q="what do I want for lunch?"'; exit 15)
	@terraform -chdir=stacks/aaaops/dev/chatgpt apply -var q="$q" -auto-approve 2>&1 | sed '0,/Outputs:/d'

##
## Safety checks
##

.PHONY: preflight-checks
preflight-checks: check-vars $(stack_dir) backend-template

.PHONY: backend-template
backend-template:
	@scripts/backend-writer go

$(stack_dir):
	$(error stack $(stack_dir) does not exist)

.PHONY: check-vars
check-vars:
ifndef ou
	$(error 'ou' is undefined [aaa/bbb/etc])
endif
ifndef env
	$(error 'env' is undefined [prod/dev/qa/uar/etc])
endif
ifndef stack
	$(error 'stack' is undefined [top level dir tree name])
endif

##
## Help
##

.PHONY: help
help:
	@echo "Usage:"
	@echo "  Make forms a path out of the env vars ou/env/stack and then runs Terraform with a 'chdir' to that path"
	@echo "  These vars can be defined when running make, but usually we export them before running make"
	@echo "  Any make task that requires Terraform remote state (most of them) also requires AWS keys to access it on s3"
	@echo "  Additional vendor-specific auth is required for the resources in question - see the README"
	@echo
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Parameters:"
	@echo "  \033[36mou=[aaa/bbb/aaaops/etc]\033[0m          OU of the managed stack"
	@echo "  \033[36menv=[prod/stag/dev/etc]\033[0m           Development environment of the stack"
	@echo "  \033[36mstack=[stack to manage]\033[0m           Specific stack to be managed"
	@echo
	@echo "  \033[36mresource=[resource name]\033[0m          Terraform reference of resource, used for import/rename"
	@echo "  \033[36mid=[resource id]\033[0m                  ID of resource, used for import"
	@echo
	@echo "Typical workflow:"
	@echo "  \033[36m(pre-auth terminal)\033[0m                Auth terminal with AWS and other vendor keys before using make"
	@echo "  \033[36mexport ou=aaa\033[0m                      Normally we export the 'stack' path items so we don't have to"
	@echo "  \033[36mexport env=dev\033[0m                              specify them on every run"
	@echo "  \033[36mexport stack=aws-vpc\033[0m"
	@echo "  \033[36mmake plan\033[0m                          Start using make targets"
	@echo "  \033[36mmake apply\033[0m"
	@echo
	@echo "Examples:"
	@grep -E '^## example ##.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = "##"}; {printf " \033[36m%s\033[0m %s\n", $$3, $$4}'

