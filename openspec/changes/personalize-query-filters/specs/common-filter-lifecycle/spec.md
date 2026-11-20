# Spec Delta

## Purpose

Allow tenant administrators to maintain common saved searches without silently changing users' preferences or hiding the effect on notification subscriptions.

## ADDED Requirements

### Requirement: Administrator-managed tenant common definitions
Only tenant administrators SHALL publish, rename, edit, or remove common filters in their tenant. A common filter SHALL have one shared name and query. Publishing SHALL make it available to the tenant, subject to personal-query precedence, without granting message permissions.

#### Scenario: Publish a common filter
- **WHEN** a tenant administrator publishes a new common filter
- **THEN** it becomes available to tenant users and is distributed according to personal-navigation rules
- **AND** users in other tenants are unaffected

#### Scenario: Rename a common filter
- **WHEN** an administrator changes its name without changing the query
- **THEN** users resolving that common filter see the new shared name
- **AND** their pinning, order, and subscriptions are unchanged

#### Scenario: Unauthorized direct edit
- **WHEN** a non-administrator submits a common-definition edit directly
- **THEN** the edit is denied even if the user has pinned or subscribed to the filter

### Requirement: Query changes require explicit impact confirmation
Before changing a common filter's query, the system SHALL require explicit administrator confirmation explaining the effect on results and subscriptions attached to that common filter. Confirmation SHALL preserve its identity, preferences, and subscription settings. Personal display precedence SHALL NOT suspend these subscriptions.

#### Scenario: Cancel a query edit
- **WHEN** an administrator changes the query but cancels the confirmation
- **THEN** the original query, preferences, and subscriptions remain unchanged

#### Scenario: Confirm a query edit
- **WHEN** the administrator confirms the presented query change
- **THEN** the same common filter executes the new query
- **AND** its existing pinning positions, explicit unpins, and subscription event selections remain attached
- **AND** personal filters with the new query retain precedence and are not altered
- **AND** existing subscriptions attached to the common filter continue even when its new query has a personal display match

#### Scenario: Confirmation does not cover a subsequently changed query
- **WHEN** the requested or stored query changes after the administrator reviewed its impact
- **THEN** the previous confirmation does not authorize that different query change

### Requirement: Complete removal with subscription impact warning
Common-filter deletion SHALL remove the definition, its personal preference records, and all its subscriptions without creating personal copies or removing messages or tags. If any subscriptions exist, the administrator SHALL see the number of distinct subscribing users and explicitly confirm cancellation before deletion.

#### Scenario: Remove a subscribed filter
- **WHEN** an administrator requests deletion of a filter subscribed to by four distinct users
- **THEN** the confirmation warns that four users' subscriptions will be cancelled
- **AND** cancellation leaves the filter and subscriptions unchanged
- **AND** confirmed deletion removes the common filter and its subscriptions atomically

#### Scenario: Personal duplicate survives common deletion
- **WHEN** an administrator deletes a common filter sharing a query with personal filters
- **THEN** those personal filters, their preferences, and their subscriptions remain unchanged
- **AND** no common definition is converted into a personal copy

#### Scenario: Common subscription is accessed under a personal name
- **WHEN** a user has a personal display match for a common query and an existing subscription attached to that common filter
- **AND** the administrator confirms removing the common filter after the subscription warning
- **THEN** that common subscription is cancelled with the removed definition
- **AND** the personal filter remains without inheriting or copying the cancelled subscription

#### Scenario: Search links survive removal
- **WHEN** a user opens the query URL of a removed common filter
- **THEN** the query still executes against authorized messages
- **AND** the deleted filter's name and subscription controls are no longer shown

#### Scenario: Subscriber count changes before confirmation
- **WHEN** the subscription impact changes after the deletion warning is displayed
- **THEN** the system refreshes the warning before accepting confirmation for deletion
