#!/bin/sh
#
# inject-okta-config.sh
#
# Xcode "Run Script" build phase that injects the Okta tenant
# configuration into the built Info.plist at BUILD TIME from the
# calling process's environment variables.
#
# Why a Run Script + plutil and not an xcconfig + $(VAR) reference:
# xcconfig $(VAR) references chain other BUILD SETTINGS, they do NOT
# interpolate shell environment variables. A Run Script DOES inherit
# Xcode's process environment, so "set env vars once on the build
# machine, then hit Run forever after" works with no step between
# `git pull` and `xcodebuild`.
#
# Behavior when OKTA_* env vars are unset:
# On CI and on fresh checkouts that have not yet configured Okta
# credentials, we do NOT want to fail the build — the four Info.plist
# keys are already declared as empty strings in project.yml, and no
# Swift code consumes them yet. We emit an Xcode `warning:` line
# (which shows up in the build log as a yellow warning, not an error)
# and exit 0 so the build proceeds with empty Okta values. Real dev
# machines that DO export the env vars hit the plutil -replace path
# below and get real values baked into the built Info.plist.
#
# Required environment variables (for a fully-configured build):
#   OKTA_ISSUER         e.g. https://example.okta.com/oauth2/default
#   OKTA_CLIENT_ID      Okta application client ID
#   OKTA_REDIRECT_URI   e.g. com.acmebank.mobile:/callback
#   OKTA_SCOPES         space-separated, e.g. "openid profile email offline_access"
#
# See README.md ("Okta build configuration") for how to set these so
# Xcode sees them at build time (launchctl setenv vs ~/.zshrc + xed).

set -e

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ -z "${OKTA_ISSUER:-}" ] || [ -z "${OKTA_CLIENT_ID:-}" ] || [ -z "${OKTA_REDIRECT_URI:-}" ] || [ -z "${OKTA_SCOPES:-}" ]; then
    echo "warning: One or more OKTA_* environment variables are unset; leaving Okta Info.plist keys empty. Set OKTA_ISSUER, OKTA_CLIENT_ID, OKTA_REDIRECT_URI, OKTA_SCOPES to inject real values."
    exit 0
fi

plutil -replace OktaIssuer      -string "${OKTA_ISSUER}"       "$PLIST"
plutil -replace OktaClientID    -string "${OKTA_CLIENT_ID}"    "$PLIST"
plutil -replace OktaRedirectURI -string "${OKTA_REDIRECT_URI}" "$PLIST"
plutil -replace OktaScopes      -string "${OKTA_SCOPES}"       "$PLIST"
