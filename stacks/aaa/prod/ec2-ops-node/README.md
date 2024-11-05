This 'backups node' is specifically for running backups jobs. The jobs can get quite long, so a lambda is not appropriate.

These nodes are not intended for troubleshooting from as a meatspace user - use the 'ops node' server or an application server/container instead

Each account is intended to have its own little backup node - this greatly simplifies permissioning. In the future we can do the cross-account stuff and unify to a single backup server in the 'shared-services' account

