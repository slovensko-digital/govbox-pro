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
If a first pinned filter is removed or becomes unavailable, the next effective pinned filter SHALL become the entry view. If none remains, the system SHALL fall back to all authorized messages. Foreign or unavailable preference records SHALL NOT make filters available.

#### Scenario: Administrator removes the user's first filter
- **WHEN** the administrator removes a common filter that was first in the user's menu
- **THEN** the next remaining effective pinned filter is used on their next entry
- **AND** if there is none, all authorized messages are shown

### Requirement: Preserve navigation at deployment
A one-time migration SHALL preserve each existing user's query shortcuts in their previous order: all messages, saved filters, then visible tag shortcuts. Equal queries SHALL collapse to one effective entry with personal precedence. Existing subscription settings SHALL survive necessary filter remapping. Migration SHALL NOT establish automatic filter creation for future tags.

#### Scenario: Existing tenant with saved filters and tags
- **WHEN** the migration runs against a populated tenant
- **THEN** users retain the query shortcuts previously available in their navigation
- **AND** all messages remains their initial first entry
- **AND** existing subscriptions retain their selected event types and processing progress

#### Scenario: Duplicate legacy shortcut
- **WHEN** a saved filter and visible tag shortcut have the same trimmed query
- **THEN** migration creates one effective menu entry for that query
- **AND** prefers the user's personal filter when one exists

#### Scenario: Fresh tenant uses the same all-messages semantics
- **WHEN** a tenant is created after deployment
- **THEN** its initial all-messages entry executes an empty query rather than a label constraint

#### Scenario: Backfill is retried
- **WHEN** an interrupted navigation backfill is rerun
- **THEN** it creates no duplicate preferences, filters within the same scope, or subscriptions
- **AND** it does not reset already established personal choices
