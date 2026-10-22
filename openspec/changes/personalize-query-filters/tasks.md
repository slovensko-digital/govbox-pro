# Tasks

## 1. Filter ownership and query identity

- [ ] 1.1 Add explicit personal/common scope and trim-only query normalization to the current `Filter` model using additive schema; permit empty-query all-messages filters and verify model tests for ownership, empty queries, outer whitespace, and preserved internal syntax.
- [ ] 1.2 Implement database-backed same-owner personal and same-tenant common uniqueness, allowing personal/common overlap; stage constraints around legacy deduplication and verify duplicate create/edit and concurrent insert tests.
- [ ] 1.3 Add the tenant-scoped effective-filter resolver with personal precedence independent of pinning; verify tests for other users, other tenants, common duplicates, unpinned personal winners, and common query edits into personal queries.
- [ ] 1.4 Update `FilterPolicy` and definition-management scopes for personal owner versus common administrator permissions without filtering by pinning; verify policy/request tests denying foreign IDs and allowing management of unpinned personal filters.
- [ ] 1.5 Document ownership, trim-only equality, common naming, and personal precedence in the project's user/developer documentation; verify examples match resolver tests and identify the tag-rename limitation explicitly.

## 2. Personal preferences and common distribution

- [ ] 2.1 Add the personal preference model/table, unique user/filter constraint, tenant-consistency validation, and cleanup associations; verify model/database tests for duplicate preferences, cross-tenant targets, and filter/user deletion.
- [ ] 2.2 Implement authorized pin/unpin/repin and per-user reorder operations with user-level locking; verify request/concurrency tests for persistent explicit unpins, append-on-repin, stable other-user order, and rejection of foreign submitted IDs.
- [ ] 2.3 Add idempotent common publication distribution and user initialization, appending only new effective pins and acknowledging personal duplicates without pinning them; verify tests for retries, publication/onboarding races, personal duplicates, and preserved defaults.
- [ ] 2.4 Initialize fresh tenants with an empty-query all-messages common default and seed new-user common order independently of existing personal menus; verify tenant/user creation tests match migrated all-messages semantics.
- [ ] 2.5 Add bounded eager-loaded menu reads that resolve precedence before pinning and never create preference rows during GET; verify query-count/no-write tests on a multi-filter user and document distribution retry behavior alongside the operation.

## 3. Query-based search and navigation UI

- [ ] 3.1 Derive executed query before `MessageThreadsController#load_threads` using parameter presence, applying the first effective pin only when `q` is absent; verify request tests for personalized entry, explicit queries, `q=`, no pins, and no automatic redirect.
- [ ] 3.2 Replace separate tag/saved-filter menu presentation with the effective personal ordered list and query-only links; verify component/system tests for independent order, active state, unpinned personal suppression, and common names without aliases.
- [ ] 3.3 Update search and clear-search controls to display/save the complete query and emit explicit empty `q` for all messages; verify browser tests refining `label:(NASES)` with text, saving the full query, and clearing a nonempty default filter.
- [ ] 3.4 Carry the executed query through scrolling, refresh, box-context navigation, and bulk-action header restoration; verify tests preserve empty `q`, cursor consistency, current box restrictions, accessible box IDs, and user-relative parsing.
- [ ] 3.5 Add accessible filter-management pinning/order controls using existing Turbo/Stimulus and generic icons; verify keyboard/browser tests show unpinned filters remain editable and repinnable, and document the first-pin/default-view behavior.

## 4. Subscriptions and query resolution

- [ ] 4.1 Replace independent tenant `.first` query lookups with the effective resolver for titles and subscription controls; verify request/system tests attach the correct user's subscription for both personal and common filters, including empty query.
- [ ] 4.2 Harden `FilterSubscriptionsController` to authorize target availability and subscription ownership consistently; verify forged personal/common/foreign-tenant IDs cannot create or mutate another user's subscription.
- [ ] 4.3 Apply effective-filter eligibility during both notification candidate selection and delivery, retaining but suppressing shadowed common subscriptions without resetting their settings; verify job tests for personal precedence, delayed jobs, unpinning, unshadowing without event replay, and no duplicate notifications.
- [ ] 4.4 Verify saved-filter result and notification authorization against existing tag and box restrictions, including common filters returning no authorized results; add focused regression tests and document that filter publication grants no message access.

## 5. Administrator common-filter lifecycle

- [ ] 5.1 Add administrator-only publication and shared-definition management integrated with distribution, keeping personal filters separate and preserving same-scope uniqueness; verify lifecycle request/system tests and personal-duplicate precedence.
- [ ] 5.2 Require server-validated impact confirmation for common query changes, bound to the reviewed old/new query and version; verify cancellation, confirmed stable ID/preferences/subscriptions, stale confirmation rejection, and personal-collision tests.
- [ ] 5.3 Add complete common removal with distinct subscribing-user count, explicit cancellation warning, and transactional preference/subscription cleanup; verify tests for cancel/confirm, changed impact, shadowed subscribers, unchanged personal duplicates, and fallback when the removed filter was first.
- [ ] 5.4 Handle deleted subscriptions in queued jobs and preserve valid notification-history associations during cleanup; verify background-job/history tests against actual foreign keys and confirm removed-filter query links still execute without stale metadata.
- [ ] 5.5 Document administrator publication, query-edit impact, and deletion warnings; verify the documented examples against lifecycle browser tests and capture UI evidence for confirmation and subscriber-count states.

## 6. Existing-data migration and compatibility

- [ ] 6.1 Implement a retryable migration-local snapshot/mapping backfill of current all-messages, saved-filter, and visible-tag shortcuts, preserving owner-personal rows and adding common counterparts where needed for other users; verify migration tests on populated multi-user/multi-tenant data reproduce prior query coverage and order.
- [ ] 6.2 Remap legacy subscriptions through the per-user effective mapping while retaining event selections/checkpoints, handling same-scope legacy duplicates with the documented deterministic rule and audit data; verify tests cover cross-owner subscriptions, duplicate query names, and interrupted reruns without lost settings.
- [ ] 6.3 Seed existing personal menus with all messages first, collapse effective duplicates, reconcile users created during backfill, and finalize query uniqueness/global-order changes only after mapping; verify no retry resets personal choices and new tags do not create filters or pins.
- [ ] 6.4 Document and rehearse phased cutover, distribution recovery, backup/audit checks, and data-preserving rollback with a navigation-read rollout switch; verify the runbook on a seeded database and record before/after shortcut and subscription counts.
- [ ] 6.5 Publish the known limitation that tag renaming does not rewrite saved queries or old links; verify documentation does not promise automatic repair and migration tests introduce no permanent tag-filter callback.

## 7. Integrated acceptance

- [ ] 7.1 Run the affected model, policy, request, job, migration, and system suites together using the repository's test setup; record exact commands/results and resolve regressions without weakening assertions or introducing conditional test clicks.
- [ ] 7.2 Exercise a browser acceptance journey with an administrator and two users: reorder defaults, clear search, publish into pinned/unpinned personal duplicates, confirm query edit, and cancel/confirm subscribed deletion; retain UI evidence and verify each user's menu and deliveries match the specs.
- [ ] 7.3 Validate the completed OpenSpec change and review the final diff against PR #249 context; verify no `filter_id` message-list URL dependency, automatic new-tag filter creation, group/template feature, or tag-rename rewrite was introduced.
