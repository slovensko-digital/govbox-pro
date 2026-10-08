# access-tags Specification

## Purpose

Defines how classification and access tags differ, who may manage a tag assignment on a thread, and the group permission that grants the ability to manage access tags.

## Requirements

### Requirement: Tag kinds and thread visibility

For ordinary tags, a tag linked to at least one group SHALL grant thread access to members of those groups. An ordinary tag without groups SHALL be a classification tag and SHALL NOT grant access. A user SHALL see a thread only when they can access its box and at least one tag on the thread is linked to one of their groups. Multiple access tags SHALL provide alternative, not cumulative, membership conditions.

#### Scenario: Tag with groups is an access tag
- **WHEN** a tag is assigned to one or more groups
- **THEN** it grants its groups an access path to threads carrying the tag, subject to box access

#### Scenario: Multiple access tags provide alternative access paths
- **WHEN** a thread carries Finance and Legal access tags and a user belongs to Finance but not Legal
- **THEN** the user can see the thread if they can access its box

#### Scenario: Tag access does not bypass box access
- **WHEN** a user's group is linked to a tag on a thread but the user cannot access its box
- **THEN** the user cannot see the thread

#### Scenario: Tag without groups is a classification tag
- **WHEN** a tag belongs to no group
- **THEN** it is treated as a classification tag that does not affect visibility

### Requirement: Who may manage a tag assignment on a thread

A user SHALL be allowed to change a visible ordinary tag assignment only on a thread they can access, and only if the tag grants no access or one of their groups has the access-tag management permission. Creating or owning a tag SHALL NOT exempt a user from this permission. The same rule SHALL apply to single-thread and bulk changes. This permission SHALL NOT itself grant thread or box visibility.

#### Scenario: Management permission does not grant thread visibility
- **WHEN** a user has access-tag management permission but cannot access a thread
- **THEN** the permission does not make that thread accessible for viewing or tag assignment

#### Scenario: Classification tag is manageable
- **WHEN** a user who can see the thread changes a classification tag
- **THEN** the change is applied

#### Scenario: Access tag is locked for an ordinary user
- **WHEN** a user without the permission changes an access tag
- **THEN** the server ignores the change

#### Scenario: Creator may assign their classification tag
- **WHEN** a user without the permission creates an ordinary tag without groups
- **THEN** the user may add or remove it on threads they can access

#### Scenario: Creator cannot assign their access tag without permission
- **WHEN** groups are assigned to an ordinary tag created by a user without the permission
- **THEN** that user cannot add or remove the tag on threads, despite remaining its owner

#### Scenario: Owning an access tag does not bypass permission in bulk
- **WHEN** a user without the permission submits a bulk addition or removal of an access tag they own
- **THEN** the server ignores that tag's changes on all selected threads

#### Scenario: Permission-holding group may manage access tags
- **WHEN** the user belongs to a group with the access-tag management permission
- **THEN** the user may manage access tags

#### Scenario: Admin may manage access tags
- **WHEN** the user is a member of the admin group
- **THEN** the user may manage access tags through the admin group's permanently enabled permission

#### Scenario: Bulk change follows the same rule
- **WHEN** the user changes tags on several threads at once
- **THEN** only tags the user may manage are applied

#### Scenario: Tampered request is ignored
- **WHEN** a request includes a change to a tag the user may not manage
- **THEN** the server applies no change for that tag

### Requirement: Non-manageable tags are shown but locked

The tag assignment list SHALL include the tenant's visible ordinary tags, including those the user may not manage, subject to the existing search filter. Hidden and system tags SHALL remain outside this list. A non-manageable tag SHALL be disabled and SHALL submit no assignment value, while a manageable tag SHALL stay editable.

#### Scenario: Access tag rendered as locked for an ordinary user
- **WHEN** an ordinary user opens the tag assignment list
- **THEN** non-manageable tags are disabled and submit no assignment value

#### Scenario: Manageable tag stays interactive
- **WHEN** the user may manage a tag
- **THEN** it is rendered as an editable checkbox that submits its assignment

### Requirement: Group permission grants access-tag management

An admin SHALL be able to grant or revoke the access-tag management permission on non-admin groups. Every user SHALL hold the permission when any of their groups has it. The admin group's permission SHALL always be enabled and SHALL NOT be revocable.

#### Scenario: Admin grants the permission
- **WHEN** an admin enables the permission on a group
- **THEN** members of that group may manage access tags

#### Scenario: Only admins change the permission
- **WHEN** a non-admin attempts to change the permission
- **THEN** the change is rejected

#### Scenario: Admin group shows an always-enabled permission
- **WHEN** an admin opens the admin group's permissions page
- **THEN** access-tag management is shown with a localized "Always enabled" status without a toggle to disable it

#### Scenario: Attempt to disable admin access-tag management
- **WHEN** a request attempts to disable access-tag management for the admin group
- **THEN** the request is rejected and admins retain the ability to manage access tags

#### Scenario: New admin group has the permission enabled
- **WHEN** an admin group is created
- **THEN** its access-tag management permission is enabled and cannot be saved as disabled

#### Scenario: Existing disabled admin group is repaired
- **WHEN** the upgrade encounters an admin group with the permission disabled
- **THEN** its permission is enabled before the upgraded application relies on it

### Requirement: Existing groups keep the ability on upgrade

On upgrade, existing groups SHALL be granted the permission so current users do not lose the ability. Non-admin groups created afterwards SHALL start without it; admin groups SHALL always have it enabled.

#### Scenario: Grandfather existing groups
- **WHEN** the upgrade runs against a database with existing groups
- **THEN** the existing groups are granted the permission

#### Scenario: New group starts without the permission
- **WHEN** a non-admin group is created after the upgrade
- **THEN** it does not have the access-tag management permission

### Requirement: Signature-request and automation flows are exempt

Manageability enforcement SHALL apply only to manual single-thread and bulk assignment of visible ordinary tags. Signature-request tags and automated assignments, including automation, FS and UPVS flows, SHALL NOT be subject to the access-tag management permission.

#### Scenario: Signature-request flow is unaffected
- **WHEN** a signature is requested through the signing or automation flow
- **THEN** the signature-request tag is assigned regardless of the access-tag management permission
