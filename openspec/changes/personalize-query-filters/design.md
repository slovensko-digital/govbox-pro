# Design

## Context

See `proposal.md` for motivation and the three capability deltas for the behavioral contract.

The checkout is current main (`718af8c9` when inspected), not PR #249. Current `Filter` records contain query/name/author and tenant-global position. `FilterPolicy::ScopeShowable` exposes all tenant filters, while editing is restricted to the author or an administrator. `ApplicationController#set_menu_context` builds separate saved-filter and visible-tag lists; `SidebarMenu` prepends all messages. The tag shortcut query is already `label:(name)`.

`MessageThreadsController` loads messages in a before-action and later looks up subscriptions using an unrestricted tenant query match. `FilterSubscriptionsController` also finds filters tenant-wide. `FilterSubscription` already owns event selections and `last_notify_run_at`; `Filter` already destroys its subscriptions. Notification matching and delivery occur in separate background jobs, so lookup precedence must be enforced both when scheduling and when delivering.

The old PR's STI filters, `filter_id` message-list links, callback-created tag filters, and eager creation of every possible user visibility record are not prerequisites and must not be copied wholesale. Current box permissions and user-relative query parsing must survive this change.

## Goals / Non-Goals

**Goals:**
- One effective query/filter resolver for list metadata, navigation, management context, and notification eligibility.
- Stable internal identities for mutable common filters, but query-based public message-list links.
- Transactional, idempotent preference updates with bounded menu reads and an auditable compatibility backfill.
- Preserve subscriptions and search authorization across current-main integration.

**Non-Goals:**
- Query parsing redesign, automatic tag-rename repair, group-specific distribution, reusable template UI, and unrelated PR cleanup.
- Giving administrators control over personal menu order or giving a saved filter authority over message access.

## Decisions

### 1. Keep plain saved queries; distinguish ownership explicitly

Extend the existing `Filter` with explicit personal/common scope rather than STI by query kind. Personal rows belong to an author in the tenant; common rows are tenant-managed. Keep creator attribution separately from authorization if retaining `author_id` on common records. No general `TagFilter` is needed: a tag shortcut is an ordinary query. Empty string is a valid saved query for all messages; `nil` is normalized to empty only at the search boundary, not treated as an absent request parameter.

Store the query with outer whitespace trimmed. Enforce uniqueness in the database within `(tenant, personal owner, query)` and `(tenant, common scope, query)` using appropriate partial indexes. Personal/common overlap is intentionally legal. Do not lowercase, reorder tokens, or collapse internal whitespace. Create attempts against an existing same-owner personal query return that record; same-scope edits into a duplicate fail validation. These are technical defaults to make the agreed one-query rule deterministic.

Alternative: one global row per tenant/query would make personal ownership and common naming conflict and would require destructive automatic merging. Rejected in favor of explicit precedence.

### 2. Centralize availability and precedence, independently of pinning

Resolve candidates only within the current tenant: the user's personal rows plus common rows. A personal query shadows any equal common query even if its preference is unpinned. Resolve the effective set before applying visible pins or selecting the first entry. Use this same resolution for the page title and subscription controls, instead of independent `.first` lookups.

Only the owner edits personal definitions; tenant administrators edit common definitions. An administrator's personal filter is still personal unless explicitly published. Editing and deletion scopes must not use pin visibility. Preference and subscription mutations must validate both ownership of the mutated user record and availability of its target filter; a supplied foreign ID is never sufficient.

Common management lists can still show common definitions to administrators even when their own personal query shadows one. Ordinary user navigation resolves only the personal winner. Personal filters keep their own name when overriding a common filter; there is no personal alias for the common row.

Alternative: reject common publication if any user has the query. Rejected because users could prevent administrators publishing common defaults. Automatic merging is also rejected by the agreed personal-wins rule.

### 3. Store personal preferences by stable filter ID

Add a `UserFilterVisibility`-style preference model with `user_id`, `filter_id`, `visible`, and `position`, a unique `(user_id, filter_id)` constraint, and cascading cleanup. Validate tenant consistency. Position belongs to the user's pin, not the filter; legacy global positions are only migration/bootstrap ordering inputs.

Rows are needed for actual personal pins and explicit unpins, and for automatically distributed common defaults. Do not create a row for every searchable tag or query. Explicit unpin records are necessary because absence must not cause a later common-default pass to repin a filter.

Append and reorder under a per-user lock; validate all submitted preference IDs, reject foreign IDs, and update order atomically. Consecutive positions can be assigned without importing the PR's draggable dependency or assuming drag-and-drop is necessary. Use existing Turbo/Stimulus patterns and generic icon components; accessible up/down controls are sufficient.

Repinning appends to the current menu. Queries shadowed by personal filters are excluded dynamically rather than rewriting the common filter's stored preferences. If a personal filter later disappears, an existing common preference can become effective again according to its own state; do not copy the deleted personal state into it. This is a planning default, not automatic merging.

### 4. Distribution is an idempotent lifecycle operation, not a GET side effect

Common publication appends default pins for existing tenant users who lack an equal personal query. User initialization applies current common defaults in initial order; start fresh tenants with an empty-query all-messages common filter. Serialize initial ordering and publication against user initialization and make per-user insertion idempotent. Preserve any existing preference, especially explicit unpins. A common initial-order field is a bootstrap input only and is never replayed over personal order.

For users with a personal duplicate, record a non-visible common distribution preference to acknowledge publication without displaying a second pin. This prevents a later generic backfill from pinning it unexpectedly. Existing common preferences shadowed by a later personal filter remain untouched.

Use bounded batches for publication/backfill and make job retries safe if distribution is asynchronous; publication should expose progress/failure to the administrator rather than silently losing users. Menu reads use eager-loaded, already-established preferences and a request-local effective set, not writes or repeated `save!` calls.

Alternative: copy the shared list on every page load. Rejected because it creates write-heavy GETs, races, and risks overriding explicit personal choices.

### 5. Distinguish entry from explicit empty search by parameter presence

Before `load_threads`, derive the executed query: if the request contains `q`, use its trimmed value, including `q=`; otherwise use the first effective pinned filter's query, or empty string. Render the list without an automatic redirect. Put that executed query in the search field and explicitly carry it into scroll URLs and actions that preserve search context.

All-messages links and clear-search actions emit an explicit empty `q`; do not compact or discard it as blank. Query URLs never require `filter_id`. Root/entry links intentionally have no `q` and mean the personal default. This internal distinction does not add a user-visible search mode.

The search field contains the complete executed query, so refining a label search naturally retains its label expression and saving records the whole query. Preserve existing box context, accessible box IDs, authorization scope, cursor behavior, and user-relative query parsing. Header, active menu state, and notification controls use the same query context, including when bulk selection is cleared.

Alternative: retain `filter_id` plus text or always redirect root to the first filter. Rejected: the former introduces hidden search constraints; the latter changes root behavior and can accidentally constrain explicit links.

### 6. Stable common-filter edits, explicit confirmations, and non-destructive shadowing

Changing a common query preserves its row ID, preferences, and subscriptions. Bind the server-validated confirmation to the before/after query and record version so a stale dialog cannot authorize a different edit. Personal collisions are allowed and resolved dynamically; another common row with the same query fails same-scope uniqueness validation.

An effective-subscription predicate is checked in both `ReindexAndNotifyFilterSubscriptionsJob` candidate selection and `NotifyFilterSubscriptionJob` delivery. Shadowed common subscriptions retain their settings but cannot create duplicate notifications; they become eligible again only when that common filter resolves as effective. Do not replay past events solely because a filter becomes unshadowed. Deleting or unpinning are distinct: unpinning never disables the effective filter's subscriptions.

This shadowed-subscription policy is a technical consequence of the agreed personal-wins behavior; it avoids inventing a subscription-event union or silently deleting an existing common subscription. Test delayed jobs across personal creation, common edits, unshadowing, and deletion. Common query edits affect future notification matching without resetting the existing checkpoint.

Deletion uses the existing subscription association's dependent cleanup plus preference cleanup in one transaction. Present distinct subscribing-user count, including temporarily shadowed subscriptions, and cancel nothing before confirmation. Serialize subscription mutation with common deletion and revalidate the impact count/version when accepting confirmation. Inspect existing notification history associations and foreign keys so cleanup leaves no broken history links. Handle queued jobs whose subscription disappeared safely. No personal copy is produced.

### 7. Migrate the current navigation, not the old PR's schema history

Introduce additive schema first and a separately retryable, batched data backfill. Capture each tenant's previous ordered shortcuts before changing ownership or navigation reads: all messages, existing filters by position/ID, visible tags by name/ID. Render tag queries exactly as the current component does. Migration creates tag-derived saved filters only for this existing snapshot, never a future tag callback.

Preserve author-owned definitions as personal where possible. Since current main exposes these searches to all tenant users, create common counterparts where needed to preserve other users' existing shortcuts. Use a persistent old-filter/user-to-effective-filter mapping to move subscriptions to the correct personal or common row without resetting event selections or processing checkpoints. Existing IDs can remain for their personal owner; do not simply hide everybody else's former filters by changing the policy scope.

Legacy duplicate-query technical default: keep the first existing menu occurrence as the common label/order source, prefer each user's own personal row as the effective definition, and union event selections only when migration must collapse multiple legacy subscriptions within the same user's same-query scope. Keep the earliest checkpoint when collapsing such legacy duplicate subscriptions to avoid silently dropping pending events, and preserve the original mapping/settings for audit and rollback. This exceptional compatibility consolidation is not ongoing personal/common merging. Record duplicate counts and verify mapping before destructive cleanup.

Seed preferences in the old order, collapse effective duplicates, and place the empty-query all-messages filter first. Backfill must be restartable without resetting an already completed user's choices. Build indexes after deduplication; use migration-local models or explicit SQL rather than application callbacks that evolve over time.

Alternative: copy every visible tag into filters through a permanent callback. Rejected by the explicit decision that new tags do not create filters and by fresh/existing tenant inconsistencies in the old PR.

## Risks / Trade-offs

- [Common queries can show fewer or no results for some users] -> Describe them as saved searches over authorized messages, never permission grants; test list and notification authorization including box restrictions.
- [A private duplicate hides a common filter even while unpinned] -> Make the personal winner visible in filter management and explain the precedence; do not silently repin the common duplicate.
- [Query equality is deliberately weak] -> Trim outer whitespace consistently in writes, resolution, and migration; accept that equivalent differently written queries remain distinct.
- [Tag renames break literal label references and old links] -> Explicitly document this known limitation; do not add rename rewriting or aliases within this change.
- [Legacy menu preservation needs common counterparts and subscription remapping] -> Audit counts/mappings and test populated multi-user/multi-tenant data before switching reads. No claim of preserving multiple legacy aliases for the same query: one effective query entry intentionally wins.
- [Publication and reordering can race] -> Unique constraints, user-level locking, bounded idempotent distribution, and concurrent-request tests.
- [Changing a common query can change or temporarily suppress deliveries] -> Explicit administrator warning, stable subscription identity, and precedence checks at delivery time.
- [All-messages entry is unpinned or removed] -> Clear search remains available independently; empty effective menu falls back to authorized all messages.

## Migration Plan

1. Add scope and preference schema plus constraints that can coexist with current data; retain old columns during rollout. Add a rollout switch for switching navigation reads only after successful backfill.
2. Run the snapshot/mapping backfill on a production-like copy, including duplicate-query and cross-owner subscription cases. Verify query coverage, event selections/checkpoints, and all-messages-first order.
3. Run batched backfill in deployment; reconcile users/common publication created during the run using the same idempotent path. Pause filter-definition writes during final reconciliation/cutover if needed, not through an unbounded lock over the whole tenant.
4. Enable resolver-based navigation, explicit-empty-query handling, lifecycle confirmations, and subscription eligibility together. Run smoke tests for old query links, per-user defaults, common publication, personal overrides, notification settings, and fresh tenant creation.
5. Keep mapping/audit data and legacy ordering until verification finishes. Drop obsolete global-order constraints and old presentation paths only when safe.
6. Rollback before cutover can disable new reads and remove only new schema after retaining backfill data. After users create preferences or common filters, prefer a forward fix or disable personalized reads while retaining all new data; do not automatically down-migrate away user settings or resurrect cancelled subscriptions. A destructive restoration requires the deployment backup and an explicit operational decision.
