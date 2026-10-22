# Spec Delta

## Purpose

Define saved searches whose query-based links remain meaningful independently of personal navigation, with deterministic personal/common resolution and secure subscription lookup.

## ADDED Requirements

### Requirement: Query-based message-list links
The system SHALL represent an explicit message search using `q`, without requiring `filter_id`. It SHALL execute the complete supplied query independently of the user's default filter. Saving a search SHALL use the complete query displayed in the search field.

#### Scenario: A shared search link ignores personal defaults
- **WHEN** two users with different default filters open the same explicit `q` URL
- **THEN** both execute the supplied query without an additional default-filter constraint
- **AND** each sees only messages allowed by their existing permissions

#### Scenario: Save a combined search
- **WHEN** a user searches for `label:(NASES) faktúra` and saves the result as a filter
- **THEN** the saved query includes both the label constraint and the text
- **AND** reopening it requires no hidden filter context

### Requirement: Lightweight query equality
The system SHALL compare saved queries after trimming leading and trailing whitespace only. It SHALL enforce uniqueness within each owner's personal filters and within the tenant's common filters, while allowing a personal and common filter to share a query.

#### Scenario: Repeated personal save
- **WHEN** a user saves a personal query already present in their personal filters with only outer whitespace differing
- **THEN** the existing personal filter is returned rather than creating a duplicate

#### Scenario: No semantic normalization
- **WHEN** queries differ in internal whitespace, case, or condition order
- **THEN** they are not treated as equal merely because they might return equivalent results

#### Scenario: An owner edits into a same-scope duplicate
- **WHEN** an edit would duplicate another query in the same personal-owner or common-tenant scope
- **THEN** the edit is rejected without changing either filter or its subscriptions

### Requirement: Personal filters override common duplicates
For a user and query, the system SHALL resolve at most one effective saved filter: that user's personal match first, otherwise their tenant's common match. Pinning SHALL NOT affect precedence. Common publication or editing SHALL NOT merge or overwrite personal filter data.

#### Scenario: Administrator publishes an existing personal query
- **WHEN** an administrator publishes a query already saved personally by a user
- **THEN** that user continues to see their personal name, pinning, order, and subscription settings
- **AND** other users without a personal match resolve the common filter

#### Scenario: An unpinned personal filter still wins
- **WHEN** an unpinned personal filter and a pinned common filter have equal queries
- **THEN** the common duplicate is absent from that user's menu
- **AND** opening the query resolves the personal filter

#### Scenario: Existing common filter changes into a personal query
- **WHEN** an administrator confirms changing a common filter to a user's personal query
- **THEN** the user's personal filter wins without blocking the administrator's edit
- **AND** the personal filter and its subscriptions are not merged into the common filter

### Requirement: Filter ownership and management are independent of pinning
Users SHALL manage their own personal filters regardless of pinning. Only tenant administrators SHALL publish or change common definitions. Common names SHALL be shared, without personal aliases. Users SHALL NOT access another user's personal definitions through direct management or subscription requests.

#### Scenario: Edit an unpinned personal filter
- **WHEN** a user opens filter management after unpinning their personal filter
- **THEN** the filter remains available for editing, deletion, and repinning

#### Scenario: Shared name is not locally editable
- **WHEN** a non-administrator uses a common filter
- **THEN** they can change their pinning, order, and notifications but not its name, query, or common status

#### Scenario: Foreign filter identifier
- **WHEN** a user submits another user's personal filter identifier or another tenant's filter identifier to a preference or subscription endpoint
- **THEN** access is denied and no preference or subscription is changed

### Requirement: One effective filter context for subscriptions
Search titles and subscription controls SHALL resolve the same effective filter by query. A common filter shadowed by a personal match SHALL NOT produce a second active subscription for that user's same query. Existing shadowed common subscriptions SHALL retain their settings but SHALL NOT deliver until the common filter becomes effective again.

#### Scenario: Return to a saved query
- **WHEN** a user opens a query matching their effective saved filter
- **THEN** the page displays that filter's name and that user's existing subscription controls

#### Scenario: Personal filter shadows an existing common subscription
- **WHEN** a personal filter takes precedence over a subscribed common filter of the same query
- **THEN** the common subscription does not deliver while shadowed
- **AND** no subscription settings are copied or automatically merged

#### Scenario: Old query remains a valid search after edit or deletion
- **WHEN** a saved filter's query changes or the filter is deleted and a user opens its old query URL
- **THEN** the original query is executed as a search
- **AND** metadata and subscriptions are attached only if another effective filter matches that query

### Requirement: Filters do not grant message access
Common availability, personal pinning, and saved query matching SHALL NOT grant access to messages, boxes, or tags. Existing authorization SHALL remain authoritative for message results and notifications.

#### Scenario: A common filter matches inaccessible messages
- **WHEN** a common filter's query matches messages the user cannot access
- **THEN** those messages remain excluded from results and notifications

### Requirement: Tags do not implicitly create filters
Creating a tag SHALL NOT create or publish a saved filter. Changing tag display visibility SHALL NOT rewrite personal filter preferences. Saved filters SHALL remain ordinary queries; automatic query rewriting and old-name aliases after tag renames are outside this capability.

#### Scenario: Create a tag
- **WHEN** a tag is created
- **THEN** it can be searched using the existing label query syntax
- **AND** no saved filter or menu pin is automatically created

#### Scenario: Hide a tag on threads
- **WHEN** an administrator changes a tag's display visibility
- **THEN** existing saved filter definitions and personal pinning preferences remain unchanged
