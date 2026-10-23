# Spec Delta

## Purpose

Provide a personalized ordered menu of saved searches while keeping explicit searches stable and preserving the navigation available before deployment.

## ADDED Requirements

### Requirement: Personal pinning and ordering
Each user SHALL control the pinning and order of their effective filters independently. A newly saved personal filter SHALL be appended as pinned. Reordering SHALL affect only that user. An explicit unpin SHALL persist across subsequent visits and common-filter distribution.

#### Scenario: Independent order
- **WHEN** one user moves a common filter to the first position
- **THEN** it becomes first only in that user's menu
- **AND** other users retain their existing order

#### Scenario: Explicitly unpin a common filter
- **WHEN** a user unpins a common filter and later reloads the application
- **THEN** the filter remains available to repin but absent from their menu
- **AND** default distribution does not recreate the pin

#### Scenario: Repin a filter
- **WHEN** a user repins an unpinned filter
- **THEN** it is appended after their currently pinned effective filters

### Requirement: First pinned filter is the entry view
Opening the message list without an explicit query SHALL select the first effective pinned filter. Without any effective pinned filters, it SHALL show all authorized messages. This selection SHALL NOT change the meaning of an explicit query or an explicit all-messages action.

#### Scenario: Personalized entry
- **WHEN** a user opens the message-list entry with no explicit query and their first pinned filter is `-label:(Vybavené)`
- **THEN** that filter's query is used as their initial view
- **AND** the search field shows the query actually being executed

#### Scenario: Empty personal menu
- **WHEN** the user opens the entry with no effective pinned filters
- **THEN** all messages accessible in the current box context are shown

### Requirement: Explicit all-messages navigation bypasses the default
Clearing search or selecting the all-messages shortcut SHALL execute an empty query without reapplying the default filter. All messages SHALL mean all authorized messages in the current box context. The all-messages shortcut SHALL participate in personal pinning and ordering like other filters.

#### Scenario: Clear a nonempty default search
- **WHEN** a user clears search while their first pinned filter has a nonempty query
- **THEN** all authorized messages in the current box context are shown
- **AND** the default filter is not automatically reapplied

#### Scenario: Explicit all-messages link
- **WHEN** a user opens an explicit empty-query URL or selects all messages
- **THEN** the empty query is preserved through scrolling and page refresh

### Requirement: Publish common filters without changing personal defaults
A newly published common filter SHALL be automatically appended for existing tenant users without an equal personal query. New users SHALL receive the current common defaults in their initial order. Publication SHALL NOT reorder existing pins or reinstate an explicitly unpinned filter.

#### Scenario: Existing user's menu receives a new filter
- **WHEN** an administrator publishes a new common query
- **THEN** it appears after the user's existing pinned filters
- **AND** the user's first filter and entry view remain unchanged

#### Scenario: Personal duplicate is not appended
- **WHEN** the user already has an equal personal query, pinned or unpinned
- **THEN** the newly published common duplicate is not added to their menu

#### Scenario: Onboard a new user
- **WHEN** a new user is initialized
- **THEN** the tenant's common defaults are pinned in their initial order
- **AND** subsequent personal ordering is independent of that initial order

### Requirement: Losing an effective first filter has a deterministic fallback
After a filter is removed or becomes unavailable, the system SHALL recompute the effective personal menu and use its first pinned entry as the entry view. If none remains, it SHALL fall back to all authorized messages. Foreign or unavailable preference records SHALL NOT make filters available.

#### Scenario: Administrator removes the user's first filter
- **WHEN** the administrator removes a common filter that was first in the user's menu
- **THEN** the next remaining effective pinned filter is used on their next entry
- **AND** if there is none, all authorized messages are shown

### Requirement: Removing a personal override restores the common preference
Deleting a personal filter that overrides a common filter SHALL restore the common filter's own stored pinning and position. The personal filter's preferences SHALL NOT be copied to it. The restored common filter SHALL participate in default-view selection at its original position.

#### Scenario: Common filter was pinned before the personal override
- **WHEN** a user deletes a personal override of a common filter previously pinned first
- **THEN** the common filter returns at its stored first position and becomes the default entry view
- **AND** the personal filter's position is not transferred

#### Scenario: Common filter was unpinned
- **WHEN** a user deletes a personal override and the common filter's stored preference is unpinned
- **THEN** the common filter becomes available in settings but remains absent from the menu
- **AND** its subscription settings are not changed by the display-precedence change

### Requirement: Keep system-tag shortcuts in personalized navigation
Personalized navigation SHALL retain visible system-tag search shortcuts alongside saved filters without automatically creating saved filter definitions for tags. It SHALL include tenant-visible system statuses and only the current user's own signer-specific `SignatureRequestedFromTag` and `SignedByTag` shortcuts; another user's signer-specific shortcuts SHALL NOT appear. A system shortcut SHALL not be duplicated when the same query is already represented by a pinned personal filter.

#### Scenario: Existing system status shortcuts remain available
- **WHEN** personalized navigation is enabled
- **THEN** visible system tags such as drafts, archived, signature status, and processing/error states remain query links in a "Rýchle odkazy" section labeled as searches by tags
- **AND** all-messages remains the empty-query saved-filter entry

#### Scenario: Signer-specific shortcuts are user-relative
- **WHEN** the tenant has signer-specific tags for multiple users
- **THEN** each user sees their own request-to-sign and signed-by shortcuts
- **AND** does not see another user's signer-specific shortcuts

#### Scenario: Creating later tags does not create saved filters
- **WHEN** a later visible system tag becomes available
- **THEN** it can appear as a system navigation shortcut
- **AND** no saved filter or personal pin is created for it

### Requirement: Separate filter definitions from personal menu preferences
The "Filtre" page SHALL manage saved-search definitions and common-filter subscriptions. A separate "Moje menu" page SHALL manage the current user's pinning and order. The filter-definition page SHALL NOT contain pin or order controls. Explanatory copy SHALL distinguish a saved filter from a tag on a message and clarify that menu visibility does not change message tags or notification subscriptions.

#### Scenario: Manage a saved search
- **WHEN** a user opens "Filtre"
- **THEN** the page describes and manages saved searches
- **AND** it links users to "Moje menu" for navigation preferences
- **AND** it does not render pinning or ordering controls

#### Scenario: Personalize the sidebar
- **WHEN** a user opens "Moje menu"
- **THEN** they can pin, unpin, and reorder effective filters independently
- **AND** explanatory copy states that this does not change tags on messages or notification subscriptions

### Requirement: Preserve navigation at deployment
A one-time migration SHALL preserve current query shortcuts in their previous order: all messages, saved filters, then visible tags. Existing saved filters SHALL become common definitions with unchanged IDs. Existing subscriptions, their associations, event selections, and checkpoints SHALL remain unchanged. Visible tag shortcuts SHALL be created as common query filters only during migration, not for future tags.

#### Scenario: Existing tenant with saved filters and tags
- **WHEN** the migration runs against a populated tenant
- **THEN** users retain the query shortcuts previously available in their navigation
- **AND** all messages remains their initial first entry
- **AND** existing filters retain their IDs as common definitions without personal copies
- **AND** existing subscriptions retain their IDs, filter associations, selected event types, and processing progress

#### Scenario: Existing author without administrator rights
- **WHEN** an existing author's tenant-visible filter becomes common during migration
- **THEN** its definition becomes administrator-managed
- **AND** the author retains personal pinning, order, and subscription controls rather than common-definition editing rights

#### Scenario: Duplicate legacy shortcut
- **WHEN** a saved filter and visible tag shortcut have the same trimmed query
- **THEN** migration reuses the saved filter for one effective menu entry rather than creating a duplicate tag-derived filter
- **AND** existing saved-filter IDs and subscriptions remain unchanged

#### Scenario: Fresh tenant uses the same all-messages semantics
- **WHEN** a tenant is created after deployment
- **THEN** its initial all-messages entry executes an empty query rather than a label constraint

#### Scenario: Backfill is retried
- **WHEN** an interrupted navigation backfill is rerun
- **THEN** it creates no duplicate preferences, filters within the same scope, or subscriptions
- **AND** it does not reset already established personal choices
