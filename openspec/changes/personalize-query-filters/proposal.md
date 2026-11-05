# Proposal

## Why

PR [#249](https://github.com/slovensko-digital/govbox-pro/pull/249) combines saved filters with personalized navigation, but its `filter_id` URLs, implicit tag filters, and visibility-dependent editing blur search semantics, permissions, and personal preferences. Deliver personalized navigation while retaining query-based links and adding predictable administrator-managed common filters.

## What Changes

- Keep message-list URLs query-based (`q`); resolve saved-filter metadata and the user's existing subscriptions by query after trimming its outer whitespace only. Personal display precedence must not disable an existing common subscription.
- Support personal filters and tenant-wide common filters managed by administrators. A personal filter overrides a common filter with the same query, even when unpinned; never merge their names, preferences, or subscriptions automatically.
- Store pinning and order per user. The first effective pinned filter is the user's entry view; explicit searches and clearing search never inherit an additional default constraint.
- Keep unpinned filters and their notification controls accessible in filter settings and through query links. Unpinning does not disable notifications; deleting a personal override restores the common filter's own stored pinning and order.
- Automatically append newly published common filters to existing users' menus without changing their default view. Remember explicit unpinning; administrators cannot overwrite personal order.
- Confirm common-query changes, preserving that filter's pinning and subscriptions. Warn administrators about subscribers before completely removing a common filter and its subscriptions.
- Create no saved filter automatically when a tag is created. Filters do not grant message access; pinning is independent of filter management and tag display visibility.
- Preserve today's navigation through a one-time migration. Keep existing tenant-visible filters as common filters with unchanged IDs and subscriptions, seed personal pins, and create common query shortcuts from today's visible tags only. Do not clone filters into personal/common pairs, remap subscriptions, or reset notification checkpoints.
- **BREAKING**: saved-filter management becomes explicitly personal or administrator-managed common, rather than tenant-visible filters editable by arbitrary original authors. First-entry behavior becomes personal; explicit existing `q` links retain their search meaning.
- Out of scope: group-specific filter distribution, template management, semantic query normalization, automatic rewriting after tag renames, old-tag-name aliases, and notification-job query versioning. Accept the small risk of already queued notifications reflecting a previous query after a rare edit; notification filter links continue to use the current query.

## Capabilities

### New Capabilities

- `saved-query-filters`: Query-based search identity, personal/common resolution, ownership boundaries, and subscription lookup.
- `personal-filter-navigation`: Personal pinning/order, default entry behavior, distribution of common shortcuts, and migration of existing navigation.
- `common-filter-lifecycle`: Administrator publication, confirmed edits, complete removal, and subscription impact warnings.

### Modified Capabilities

None. The project currently has no durable OpenSpec capability specifications.

## Impact

- Rails filter models, schema/migrations, `FilterPolicy`, `FiltersController`, and filter/subscription management UI.
- `ApplicationController#set_menu_context`, `SidebarMenu`, sidebar components, message-list/search components, `MessageThreadsController`, and scroll/bulk-action context.
- Existing `FilterSubscription` associations remain intact; query-level controls must expose existing subscriptions even when a personal filter wins the displayed name. Message and box authorization remains authoritative; pinning and display precedence do not change delivery eligibility.
- Model, policy, request, migration, subscription, and browser regression tests, plus operational migration and known-limitation documentation.
- Target the checked-out current `main` baseline; PR #249 at `8824a1fc8ebd7c03902356ac9294f66b5d889616` is design context, not code already present here. Do not blindly import its old migrations or unrelated changes. No new runtime dependency is assumed necessary.
