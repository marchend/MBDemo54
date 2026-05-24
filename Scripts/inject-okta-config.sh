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
# The ${VAR:?...} expansion fails the build immediately (because of
# `set -e`) with a clear message if any of the four required env vars
# is missing, rather than silently shipping an app with empty Okta
# values.
#
# Required environment variables:
#   OKTA_ISSUER         e.g. https://example.okta.com/oauth2/default
#   OKTA_CLIENT_ID      Okta application client ID
#   OKTA_REDIRECT_URI   e.g. com.acmebank.mobile:/callback
#   OKTA_SCOPES         space-separated, e.g. "openid profile email offline_access"
#
# See README.md ("Okta build configuration") for how to set these so
# Xcode sees them at build time (launchctl setenv vs ~/.zshrc + xed).

set -e

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

plutil -replace OktaIssuer      -string "${OKTA_ISSUER:?OKTA_ISSUER not set}"           "$PLIST"
plutil -replace OktaClientID    -string "${OKTA_CLIENT_ID:?OKTA_CLIENT_ID not set}"     "$PLIST"
plutil -replace OktaRedirectURI -string "${OKTA_REDIRECT_URI:?OKTA_REDIRECT_URI not set}" "$PLIST"
plutil -replace OktaScopes      -string "${OKTA_SCOPES:?OKTA_SCOPES not set}"           "$PLIST"
