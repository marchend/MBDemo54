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
# -----------------------------------------------------------------------------
# Security posture (conscious sign-off, reviewed in PR #4):
#
#   The four Okta* keys written below are baked into the built Info.plist
#   and therefore SHIP INSIDE THE .ipa. This is acceptable because the
#   Okta application backing this app is configured as a PUBLIC OIDC
#   client using Authorization-Code-with-PKCE. None of the four values
#   are confidential by the OIDC public-client threat model:
#
#     - OktaIssuer / OktaRedirectURI : public URLs by definition
#     - OktaClientID                 : public identifier in a PKCE flow,
#                                      not a secret
#     - OktaScopes                   : public list of scopes the app
#                                      requests
#
#   If this app is ever reconfigured against a CONFIDENTIAL Okta client
#   (one that carries a client secret), the secret MUST NOT be added to
#   this script or to Info.plist — it would ship in the binary. A
#   confidential client requires a server-side token exchange instead.
#
#   Similarly, if OktaScopes is expanded to include sensitive custom
#   scopes (e.g. an admin scope), recognise that the scope STRING itself
#   becomes a roadmap hint visible to anyone who unpacks the .ipa. Use
#   the most narrowly-scoped value the flow needs.
#
# Required environment variables:
#   OKTA_ISSUER         e.g. https://example.okta.com/oauth2/default
#   OKTA_CLIENT_ID      Okta application client ID
#   OKTA_REDIRECT_URI   e.g. com.acmebank.mobile:/callback
#   OKTA_SCOPES         space-separated, e.g. "openid profile email offline_access"
#
# See README.md ("Okta build configuration") for how to set these so
# Xcode sees them at build time (launchctl setenv vs ~/.zshrc + xed).
#
# Idempotency / re-execution:
#   This script is registered in project.yml with
#   `basedOnDependencyAnalysis: false`, which forces Xcode to run it on
#   EVERY build — not just when an inputFile timestamp is newer than an
#   outputFile. That is required because the script's real input is the
#   process environment, which Xcode's dependency engine can't see.
#   Without this flag, an incremental build after a `launchctl setenv`
#   change would silently keep the previously-baked values.

set -e

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

plutil -replace OktaIssuer      -string "${OKTA_ISSUER:?OKTA_ISSUER not set}"           "$PLIST"
plutil -replace OktaClientID    -string "${OKTA_CLIENT_ID:?OKTA_CLIENT_ID not set}"     "$PLIST"
plutil -replace OktaRedirectURI -string "${OKTA_REDIRECT_URI:?OKTA_REDIRECT_URI not set}" "$PLIST"
plutil -replace OktaScopes      -string "${OKTA_SCOPES:?OKTA_SCOPES not set}"           "$PLIST"
