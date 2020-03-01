#!/bin/bash

# enable strict mode
set -euo pipefail

# Helpers {{{
info() {
    echo " INFO: $*" >&2
}
die() {
    echo "ERROR: $*" >&2
    exit 1
}
# }}}

# Terraform-rendered variables {{{

# instance hostname prefix
HOSTNAME_PREFIX=${hostname_prefix}

# instance domain
DOMAIN=${domain}

# }}}

[[ -n "$HOSTNAME_PREFIX" ]] || die "HOSTNAME_PREFIX is not set"
info "  - hostname prefix: $HOSTNAME_PREFIX"
[[ -n "$DOMAIN" ]] || die "DOMAIN is not set"
info "  - domain: $DOMAIN"

ID=$(sed 's,^i-,,' </var/lib/cloud/data/instance-id)
info "read the instance id: $ID"

HOSTNAME=$HOSTNAME_PREFIX-$ID
FQDN=$HOSTNAME.$DOMAIN
info "generate hostname and fqdn"
info "  - hostname: $HOSTNAME"
info "  - fqdn: $FQDN"

info "generate '/etc/hosts'"
cat >/etc/hosts <<EOF
127.0.0.1 $FQDN $HOSTNAME
127.0.0.1 localhost.localdomain localhost
127.0.0.1 localhost4.localdomain4 localhost4

::1 $FQDN $HOSTNAME
::1 localhost.localdomain localhost
::1 localhost6.localdomain6 localhost6
EOF

info "set hostname to '$FQDN'"
hostnamectl set-hostname $FQDN
