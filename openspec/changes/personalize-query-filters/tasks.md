# Tasks

## 1. Filter ownership and query identity

- [ ] 1.1 Add explicit personal/common scope and trim-only query normalization to the current `Filter` model using additive schema; permit empty-query all-messages filters and verify model tests for ownership, empty queries, outer whitespace, and preserved internal syntax.
- [ ] 1.2 Implement database-backed same-owner personal and same-tenant common uniqueness, allowing personal/common overlap; stage constraints after the legacy collision preflight and verify duplicate create/edit and concurrent insert tests without automatic legacy merging.
- [ ] 1.3 Add the tenant-scoped effective-filter resolver with personal precedence independent of pinning; verify tests for other users, other tenants, common duplicates, unpinned personal winners, and common query edits into personal queries.
- [ ] 1.4 Update `FilterPolicy` and definition-management scopes for personal owner versus common administrator permissions without filtering by pinning; verify policy/request tests denying foreign IDs and allowing management of unpinned personal filters.
- [ ] 1.5 Document ownership, trim-only equality, common naming, and personal precedence in the project's user/developer documentation; verify examples match resolver tests and identify the tag-rename limitation explicitly.

## 2. Personal preferences and common distribution

- [ ] 2.1 Add the personal preference model/table, unique user/filter constraint, tenant-consistency validation, and cleanup associations; verify model/database tests for duplicate preferences, cross-tenant targets, and filter/user deletion.
- [ ] 2.2 Implement authorized pin/unpin/repin and per-user reorder operations with user-level locking; verify request/concurrency tests for persistent explicit unpins, append-on-repin, stable other-user order, rejection of foreign submitted IDs, and restoration of a common filter's stored pinning/position after personal-override deletion, including the first/default position.
- [ ] 2.3 Add idempotent common publication distribution and user initialization, appending only new effective pins and acknowledging personal duplicates without pinning them; verify tests for retries, publication/onboarding races, personal duplicates, and preserved defaults.
- [ ] 2.4 Initialize fresh tenants with an empty-query all-messages common default and seed new-user common order independently of existing personal menus; verify tenant/user creation tests match migrated all-messages semantics.
- [ ] 2.5 Add bounded eager-loaded menu reads that resolve precedence before pinning and never create preference rows during GET; verify query-count/no-write tests on a multi-filter user and document distribution retry behavior alongside the operation.

## 3. Query-based search and navigation UI

- [ ] 3.1 Derive executed query before `MessageThreadsController#load_threads` using parameter presence, applying the first effective pin only when `q` is absent; verify request tests for personalized entry, explicit queries, `q=`, no pins, and no automatic redirect.
- [ ] 3.2 Replace separate tag/saved-filter menu presentation with the effective personal ordered list and query-only links; verify component/system tests for independent order, active state, common-duplicate exclusion from the menu even when the personal winner is unpinned, and common names without aliases.
- [ ] 3.3 Update search and clear-search controls to display/save the complete query and emit explicit empty `q` for all messages; verify browser tests refining `label:(NASES)` with text, saving the full query, and clearing a nonempty default filter.
- [ ] 3.4 Carry the executed query through scrolling, refresh, box-context navigation, and bulk-action header restoration; verify tests preserve empty `q`, cursor consistency, current box restrictions, accessible box IDs, and user-relative parsing.
- [ ] 3.5 Add accessible filter-management pinning/order controls using existing Turbo/Stimulus and generic icons; verify keyboard/browser tests show unpinned filters remain listed with existing subscriptions indicated and notification controls, and document that unpinning preserves delivery and the first pin sets the default view.

## 4. Subscriptions and query resolution

- [ ] 4.1 Use personal-precedence resolution for query titles and query-level lookup for the user's existing subscriptions on available definitions; verify request/system tests expose and edit an existing common subscription under a personal display name, handle empty query, and do not implicitly create a duplicate subscription.
- [ ] 4.2 Harden `FilterSubscriptionsController` to authorize target availability and subscription ownership consistently; verify forged personal/common/foreign-tenant IDs cannot create or mutate another user's subscription.
- [ ] 4.3 Preserve notification delivery independently of display precedence and pinning; add regression tests proving personal-filter creation, unpinning, and personal-override deletion do not pause, copy, merge, or reset an existing common subscription or its checkpoint. Keep the current job pipeline without query versioning or queue cancellation for rare query edits.
- [ ] 4.4 Verify saved-filter result and notification authorization against existing tag and box restrictions, including common filters returning no authorized results; add focused regression tests and document that filter publication grants no message access.
- [ ] 4.5 Preserve current-query notification links and expose notification management from an unpinned filter's query view; verify browser tests keep the filter unpinned, show existing subscription controls with a personal-precedence name, and follow the source filter's current query after an edit. Document the accepted stale queued-notification risk and independent direct message/thread links.

## 5. Administrator common-filter lifecycle

- [ ] 5.1 Add administrator-only publication and shared-definition management integrated with distribution, keeping personal filters separate and preserving same-scope uniqueness; verify lifecycle request/system tests and personal-duplicate precedence.
- [ ] 5.2 Require server-validated impact confirmation for common query changes, bound to the reviewed old/new query and version; verify cancellation, confirmed stable ID/preferences/subscriptions, stale confirmation rejection, and personal-collision tests.
- [ ] 5.3 Add complete common removal with distinct subscribing-user count, explicit cancellation warning, and transactional preference/subscription cleanup; verify tests for cancel/confirm, changed impact, subscriptions accessed under personal display names, unchanged personal duplicates, and fallback when the removed filter was first. Confirm the common source's subscriptions are cancelled rather than inherited by a remaining personal filter.
- [ ] 5.4 Handle deleted subscriptions in queued jobs and preserve valid notification-history associations during cleanup; verify background-job/history tests against actual foreign keys and confirm removed-filter query links still execute without stale metadata.
- [ ] 5.5 Document administrator publication, query-edit impact, and deletion warnings; verify the documented examples against lifecycle browser tests and capture UI evidence for confirmation and subscriber-count states.

## 6. Existing-data migration and compatibility

- [ ] 6.1 Implement a retryable migration-local backfill retaining existing tenant-visible filters as common rows with unchanged IDs and adding common filters only for missing all-messages/visible-tag queries; verify populated multi-user/multi-tenant migration tests preserve query coverage and author attribution without personal/common clones, and that former non-admin authors no longer edit common definitions.
- [ ] 6.2 Add a preflight report of existing saved-query collisions, with filter IDs and subscriber counts, that stops conflicting cutover rather than silently merging rows; verify collision tests and snapshot assertions prove all existing subscription IDs, filter associations, event selections, and checkpoints remain unchanged through successful backfill and retries.
- [ ] 6.3 Seed existing personal menus with all messages first, reuse saved filters for equal visible-tag shortcuts, reconcile users created during backfill, and finalize query uniqueness/global-order changes only after preflight; verify no retry resets personal choices and new tags do not create filters or pins.
- [ ] 6.4 Document and rehearse phased cutover, distribution recovery, backup/audit checks, and data-preserving rollback with a navigation-read rollout switch; verify the runbook on a seeded database and record before/after shortcut and subscription counts.
- [ ] 6.5 Publish the known limitation that tag renaming does not rewrite saved queries or old links; verify documentation does not promise automatic repair and migration tests introduce no permanent tag-filter callback.

## 7. Integrated acceptance

- [ ] 7.1 Run the affected model, policy, request, job, migration, and system suites together using the repository's test setup; record exact commands/results and resolve regressions without weakening assertions or introducing conditional test clicks.
- [ ] 7.2 Exercise a browser acceptance journey with an administrator and two users: reorder defaults, clear search, publish into pinned/unpinned personal duplicates, manage an existing common subscription under a personal name, follow an unpinned notification link, delete a personal override to restore common order, confirm query edit, and cancel/confirm subscribed deletion; retain UI evidence and verify each user's menu and deliveries match the specs.
- [ ] 7.3 Validate the completed OpenSpec change and review the final diff against PR #249 context; verify no `filter_id` message-list URL dependency, automatic new-tag filter creation, group/template feature, tag-rename rewrite, display-precedence delivery suppression, notification-job query versioning, or migration subscription remapping was introduced.
