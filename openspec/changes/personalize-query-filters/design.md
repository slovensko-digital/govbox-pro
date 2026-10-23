# Design

## Context

See `proposal.md` for motivation and the three capability deltas for the behavioral contract.

Implementation starts from current main (`c436c394`), not PR #249 or the original proposal branch. This baseline uses Ruby 4.0.6 and Rails 8.1.4. Before this change, `Filter` records contain query/name/author and tenant-global position. `FilterPolicy::ScopeShowable` exposes all tenant filters, while editing is restricted to the author or an administrator. `ApplicationController#set_menu_context` builds separate saved-filter and visible-tag lists; `SidebarMenu` prepends all messages. The tag shortcut query is already `label:(name)`.

`MessageThreadsController` loads messages in a before-action and later looks up subscriptions using an unrestricted tenant query match. `FilterSubscriptionsController` also finds filters tenant-wide. `FilterSubscription` already owns event selections and `last_notify_run_at`; `Filter` already destroys its subscriptions. Notification matching and delivery occur in separate background jobs. Personal display precedence must not be mistaken for delivery eligibility.

The old PR's STI filters, `filter_id` message-list links, callback-created tag filters, and eager creation of every possible user visibility record are not prerequisites and must not be copied wholesale. Current box permissions and user-relative query parsing must survive this change.

## Goals / Non-Goals

**Goals:**
- One personal-precedence resolver for list metadata/navigation, with query-level access to existing subscriptions independently of which definition supplies the displayed name.
- Stable internal identities for mutable common filters, but query-based public message-list links.
- Transactional, idempotent preference updates with bounded menu reads and an auditable compatibility backfill.
- Preserve subscriptions and search authorization across current-main integration.

**Non-Goals:**
- Query parsing redesign, automatic tag-rename repair, group-specific distribution, reusable template UI, notification-job query versioning, and unrelated PR cleanup.
- Giving administrators control over personal menu order or giving a saved filter authority over message access.

## Decisions

### 1. Keep plain saved queries; distinguish ownership explicitly

Extend the existing `Filter` with explicit personal/common scope rather than STI by query kind. Personal rows belong to an author in the tenant; common rows are tenant-managed. Keep creator attribution separately from authorization if retaining `author_id` on common records. No general `TagFilter` is needed: a tag shortcut is an ordinary query. Empty string is a valid saved query for all messages; `nil` is normalized to empty only at the search boundary, not treated as an absent request parameter.

Store the query with outer whitespace trimmed. Enforce uniqueness in the database within `(tenant, personal owner, query)` and `(tenant, common scope, query)` using appropriate partial indexes. Personal/common overlap is intentionally legal. Do not lowercase, reorder tokens, or collapse internal whitespace. Create attempts against an existing same-owner personal query return that record; same-scope edits into a duplicate fail validation. These are technical defaults to make the agreed one-query rule deterministic.

Alternative: one global row per tenant/query would make personal ownership and common naming conflict and would require destructive automatic merging. Rejected in favor of explicit precedence.

### 2. Centralize availability and precedence, independently of pinning

Resolve candidates only within the current tenant: the user's personal rows plus common rows. A personal query shadows any equal common query even if its preference is unpinned. Resolve the effective display set before applying visible pins or selecting the first entry. Use it for menu entries and page titles. Separately find the user's existing subscriptions on available definitions matching that query, including a common definition hidden by the personal display match; never let title precedence silently disable an existing subscription.

Only the owner edits personal definitions; tenant administrators edit common definitions. An administrator's personal filter is still personal unless explicitly published. Editing and deletion scopes must not use pin visibility. Preference and subscription mutations must validate both ownership of the mutated user record and availability of its target filter; a supplied foreign ID is never sufficient.

Common management lists can still show common definitions to administrators even when their own personal query shadows one. Ordinary user navigation resolves only the personal winner. Personal filters keep their own name when overriding a common filter; there is no personal alias for the common row. Filter settings include unpinned definitions and show whether a subscription exists. The displayed query exposes existing subscription controls even if the subscription belongs to its common rather than personal definition.

Alternative: reject common publication if any user has the query. Rejected because users could prevent administrators publishing common defaults. Automatic merging is also rejected by the agreed personal-wins rule.

### 3. Store personal preferences by stable filter ID

Add a `UserFilterVisibility`-style preference model with `user_id`, `filter_id`, `visible`, and `position`, a unique `(user_id, filter_id)` constraint, and cascading cleanup. Validate tenant consistency. Position belongs to the user's pin, not the filter; legacy global positions are only migration/bootstrap ordering inputs.

Rows are needed for actual personal pins and explicit unpins, and for automatically distributed common defaults. Do not create a row for every searchable tag or query. Explicit unpin records are necessary because absence must not cause a later common-default pass to repin a filter.

Append and reorder under a per-user lock; validate all submitted preference IDs, reject foreign IDs, and update order atomically. Consecutive positions can be assigned without importing the PR's draggable dependency or assuming drag-and-drop is necessary. Use existing Turbo/Stimulus patterns and generic icon components; accessible up/down controls are sufficient.

Repinning appends to the current menu. Queries shadowed by personal filters are excluded dynamically rather than rewriting the common filter's stored preferences. When a personal override is deleted, the common filter resumes its own stored visible/unpinned state and original position, even if that restores it as the first/default entry. Do not copy the deleted personal state into it. This restoration is confirmed behavior, not automatic merging. Unpinning and changes to display precedence do not disable subscriptions.

### 4. Distribution is an idempotent lifecycle operation, not a GET side effect

Common publication appends default pins for existing tenant users who lack an equal personal query. User initialization applies current common defaults in initial order; start fresh tenants with an empty-query all-messages common filter. Serialize initial ordering and publication against user initialization and make per-user insertion idempotent. Preserve any existing preference, especially explicit unpins. A common initial-order field is a bootstrap input only and is never replayed over personal order.

For users with a personal duplicate, record a non-visible common distribution preference to acknowledge publication without displaying a second pin. This prevents a later generic backfill from pinning it unexpectedly. Existing common preferences shadowed by a later personal filter remain untouched.

Use bounded batches for publication/backfill and make job retries safe if distribution is asynchronous; publication should expose progress/failure to the administrator rather than silently losing users. Menu reads use eager-loaded, already-established preferences and a request-local effective set, not writes or repeated `save!` calls.

Alternative: copy the shared list on every page load. Rejected because it creates write-heavy GETs, races, and risks overriding explicit personal choices.

### 5. Distinguish entry from explicit empty search by parameter presence

Before `load_threads`, derive the executed query: if the request contains `q`, use its trimmed value, including `q=`; otherwise use the first effective pinned filter's query, or empty string. Render the list without an automatic redirect. Put that executed query in the search field and explicitly carry it into scroll URLs and actions that preserve search context.

All-messages links and clear-search actions emit an explicit empty `q`; do not compact or discard it as blank. Query URLs never require `filter_id`. Root/entry links intentionally have no `q` and mean the personal default. This internal distinction does not add a user-visible search mode.

The search field contains the complete executed query, so refining a label search naturally retains its label expression and saving records the whole query. Preserve existing box context, accessible box IDs, authorization scope, cursor behavior, and user-relative query parsing. Header, active menu state, and notification controls use the same query context, including when bulk selection is cleared. Notification filter links already use `message_threads_path(q: notification.filter.query)`: preserve this current-query behavior, resolve names with personal precedence, expose existing subscriptions, and never repin as a side effect. An old notification follows an edited filter's current query; its direct message/thread link remains independent.

Alternative: retain `filter_id` plus text or always redirect root to the first filter. Rejected: the former introduces hidden search constraints; the latter changes root behavior and can accidentally constrain explicit links.

### 6. Preserve subscriptions independently of display precedence

Changing a common query preserves its row ID, preferences, and subscriptions. Bind the server-validated confirmation to the before/after query and record version so a stale dialog cannot authorize a different edit. Personal collisions are allowed and resolved dynamically; another common row with the same query fails same-scope uniqueness validation.

Keep `FilterSubscription` attached to its existing filter ID with its existing event selections and checkpoint. Saving a personal filter or unpinning a filter does not pause, cancel, transfer, reset, or implicitly create an additional subscription. Do not introduce an effective-display-filter predicate into `ReindexAndNotifyFilterSubscriptionsJob` or `NotifyFilterSubscriptionJob`: a common subscription continues delivering even when a personal filter supplies the displayed name.

When query-level notification controls find an existing common subscription, editing or disabling them acts on that same subscription, not a newly created personal copy. Do not automatically create a second subscription merely because a personal definition wins the display query. If multiple existing subscriptions match after a common query edit, keep their identities/settings and expose their source definitions for management rather than silently merging or suspending any. Ordinary subscription create/update paths must check existing subscriptions for the query before offering to add another. This is a presentation/lookup change, not a new query-owned subscription model.

Common query edits affect future notification matching without resetting the checkpoint or triggering a retrospective scan. Accept the small race in the current two-job pipeline: a notification queued under an earlier query can still be delivered after a rare query edit. Do not add query versions, historical snapshots, queue purges, or cancellation machinery for this case. Record the limitation rather than promise exact edit-boundary semantics.

Deletion uses the existing subscription association's dependent cleanup plus preference cleanup in one transaction. Present the distinct count of users subscribed to that actual common definition, including subscriptions accessed under a personal display name, and cancel nothing before confirmation. Serialize subscription mutation with common deletion and revalidate the impact count/version when accepting confirmation. Inspect existing notification history associations and foreign keys so cleanup leaves no broken history links. Handle queued jobs whose subscription disappeared safely. No personal copy is produced; deleting a common definition cancels its own subscriptions even if a personal display match remains.

### 7. Migrate the current navigation, not the old PR's schema history

Introduce additive schema first and a separately retryable, batched data backfill. Capture each tenant's previous ordered shortcuts before changing navigation reads: all messages, existing filters by position/ID, visible tags by name/ID. Render tag queries exactly as the current component does. Migration creates common tag-derived saved filters only for this existing snapshot, never a future tag callback.

Keep every existing tenant-visible filter as a common definition with the same ID; retain author attribution for audit, not common-definition editing authority. Its existing subscriptions keep their IDs, filter associations, selected events, and `last_notify_run_at`. Do not create owner-personal/common pairs, move subscription foreign keys, or copy subscriptions. Personal definitions are created by users after rollout, not inferred from legacy authorship. The former non-admin author now uses common-filter pin/order/subscription controls rather than editing the shared definition; this permission change was explicitly accepted.

Reuse an existing common query when a visible-tag shortcut or all-messages entry would duplicate it. The first previous menu occurrence determines the seed position. Preflight existing saved queries after trim-only normalization before adding common-query uniqueness. If multiple existing saved rows already have the same query, report their IDs and subscriber counts and stop the affected cutover for explicit data resolution rather than inventing an automatic merge. This is a migration safety check, not a new deduplication policy. Never select the earliest checkpoint or union subscription events as a migration shortcut.

Seed personal preferences on the retained common definitions in the old order, collapse duplicate menu shortcuts, and place the empty-query all-messages filter first. Backfill must be restartable without resetting an already completed user's choices. Build uniqueness indexes only after preflight succeeds; use migration-local models or explicit SQL rather than application callbacks that evolve over time.

Alternative: copy every visible tag into filters through a permanent callback. Rejected by the explicit decision that new tags do not create filters and by fresh/existing tenant inconsistencies in the old PR.

## Risks / Trade-offs

- [Common queries can show fewer or no results for some users] -> Describe them as saved searches over authorized messages, never permission grants; test list and notification authorization including box restrictions.
- [A private duplicate hides a common filter even while unpinned] -> Make the personal winner visible in filter management and explain the precedence; do not silently repin the common duplicate.
- [Query equality is deliberately weak] -> Trim outer whitespace consistently in writes, resolution, and migration; accept that equivalent differently written queries remain distinct.
- [Tag renames break literal label references and old links] -> Explicitly document this known limitation; do not add rename rewriting or aliases within this change.
- [Legacy data may already contain equal saved queries] -> Preflight and report collisions before uniqueness/cutover; require explicit resolution rather than merging existing rows, subscriptions, or checkpoints. Tag-derived shortcut duplicates simply reuse an existing saved filter.
- [Publication and reordering can race] -> Unique constraints, user-level locking, bounded idempotent distribution, and concurrent-request tests.
- [A queued notification may reflect a previous common query] -> Accept this small risk for rare edits; preserve the current delivery pipeline without query-version machinery. Notification links use the source filter's current query.
- [A common query edit can make previously separate subscriptions match the same query] -> Keep existing subscriptions active and manageable; do not silently merge, suppress, or reset them based on display precedence.
- [Deleting a personal override may restore a common first/default filter] -> Restore the common filter's actual stored state and position as agreed, not the deleted personal state.
- [All-messages entry is unpinned or removed] -> Clear search remains available independently; empty effective menu falls back to authorized all messages.

## Migration Plan

1. Add scope and preference schema plus constraints that can coexist with current data; retain old columns during rollout. Add a rollout switch for switching navigation reads only after successful backfill.
2. Preflight existing saved-query collisions and rehearse the common-scope/pinning backfill on a production-like copy, including subscriptions owned by users other than the original filter author. Verify unchanged filter/subscription IDs, foreign keys, event selections/checkpoints, query coverage, and all-messages-first order. Do not silently remediate preflight failures.
3. Run batched backfill in deployment; reconcile users/common publication created during the run using the same idempotent path. Pause filter-definition writes during final reconciliation/cutover if needed, not through an unbounded lock over the whole tenant.
4. Enable resolver-based navigation, explicit-empty-query handling, lifecycle confirmations, and query-level subscription controls together. Run smoke tests for old query/notification links, unpinned subscriptions, personal-override deletion, common publication, and fresh tenant creation. Do not install display-precedence delivery suppression.
5. Keep preflight/audit results and legacy ordering until verification finishes. Drop obsolete global-order constraints and old presentation paths only when safe; existing subscription rows require no remapping.
6. Rollback before cutover can disable new reads and remove only new schema after retaining backfill data. After users create preferences or common filters, prefer a forward fix or disable personalized reads while retaining all new data; do not automatically down-migrate away user settings or resurrect cancelled subscriptions. A destructive restoration requires the deployment backup and an explicit operational decision.
