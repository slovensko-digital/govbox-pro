# Design

## Context

Tag assignment happens in two controllers: `MessageThreads::TagsController` (a single thread) and `MessageThreads::Bulk::TagsController` (several threads). Both build a `RelationChanges::Tags` diff from `tags_assignments` params against the tenant's visible `SimpleTag` scope, then persist the diff. Signature-request tags are separate `Tag` subclasses (not `SimpleTag`) and are assigned by signing, automation, FS and UPVS flows through other paths. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Enforce, at the point where a user assigns tags to a thread, that only manageable tags are changed.
- Make the rule visible in the UI without hiding tags.
- Add a group-level permission that grants access-tag management to non-admins.

**Non-Goals:**
- Changing thread visibility: box access AND a group linked to at least one thread tag remains the existing rule. Access-tag management does not grant visibility.
- Restricting signature-request tags or the automation / FS / UPVS flows.
- Per-user permissions; the unit stays the group.
- Changing tag ownership metadata, tag deletion policy, or the endpoint removal handled in the separate PR.

## Decisions

- **Group boolean `can_manage_access_tags`, mirroring `all_boxes_permission`.** Every user holds the permission when any of their groups has it, without a separate `admin?` branch. Alternative: a per-user flag (rejected — permissions in this app are granted through groups).
- **Admin groups always store true.** Default the permission to true for new admin groups and enforce the invariant at the group model boundary so ordinary application saves cannot create or update an admin group with false. Show a localized "Always enabled" status instead of a toggle and reject disable requests server-side. The column migration enables existing admin groups. Alternatives: a separate admin bypass (rejected — duplicates permission logic), or an editable true default (rejected — does not guarantee the always-enabled behavior).
- **Ownership is not an access-assignment permission.** Ordinary tag creation records the creator as owner; that metadata does not represent delegated authority to grant access. The manageable scope has no owner exemption. A classification tag remains editable without permission, but becomes locked for its creator if groups are later assigned to it. Ownership metadata and its separate signing and deletion uses remain unchanged. Alternative: retain an owner exemption (rejected — creation would confer enduring authority to distribute access after an administrator converts the tag to an access tag).
- **The migration enables only admin groups.** Existing and new non-admin groups, including all-users, personal and signer groups, require an explicit administrator grant. Rationale: safe defaults must not silently grant authority to distribute access. Admin ability is supplied by the permanently true stored group permission.
- **Enforce in the controllers through a manageable scope passed to the diff, not in model callbacks.** The diff filters `to_add` / `to_remove` to tags inside that scope. Rationale: callbacks on `Tag`/`MessageThreadsTag` would also block automation and signature flows, which must keep working.
- **Out-of-scope ids are ignored, not raised.** The shared `ids_to_tags` helper resolves ids with `where(id: ids)` instead of `find`, so a tampered request that names an unmanageable tag is silently dropped rather than causing an error.
- **Detect access tags through the `tag_groups` association, not the `tag_groups_count` counter cache.** The counter is a denormalized optimization used for rendering; making the security boundary depend on it means a stale counter could expose an access tag as manageable. The enforcement scope uses NOT EXISTS against the actual association. The unused `Tag#manageable_by?` instance predicate was removed during review; regression tests exercise the scope used by production. The display predicate and system-tag behavior remain outside this assignment change.
- **UI preserves the visible ordinary-tag list and existing search.** Hidden and system tags stay outside this list. A non-manageable tag renders as a disabled checkbox with no `name` (so it submits nothing), and its label is not clickable. `TagsAssignment::ListComponent#manageable?(tag)` hides the ID-set membership check from the template. Locked checkboxes retain the initial assigned or mixed state through search and saving. The tooltip is "Tento štítok nemáte právo meniť".
- **List preparation reuses loaded records.** `manageable_ids` is an eager `Set`, so per-tag membership checks do not query the database. `TagsFilter` loads the rows needed by the template once and reuses their IDs for an empty search instead of issuing a separate all-ID query. Non-empty search retains database `unaccent`/`ILIKE` semantics. `ListComponent#checkbox_for` uses a single initial-state assignment hash prepared by the component for locked tags; it is rendering state, not a persistence operation.
- **Group permission updates use Rails casting and model validation.** `Group` validates inclusion in `[true, false]`; `AdminGroup` additionally requires true. The new controller action updates permitted attributes and renders the permissions form with status 422 on validation failure. It does not manually cast boolean parameters. The existing `all_boxes_permission` action is unchanged.
- **Group mutability is polymorphic.** `Group#manage_access_tags_changeable?` returns true and `AdminGroup` overrides it with false. Both the policy and permissions form use this predicate instead of checking the STI class.
- **System-group permissions remain editable.** Admins can change the permission for `AllGroup`, `UserGroup` and `SignerGroup` through the permissions list, even where group membership or naming is locked. Every enabled membership contributes permission; revocation must disable all granting groups for the affected user, not just one custom group.

## Risks / Trade-offs

- [Stale `tag_groups_count` counter] → resolve access tags via the association in the enforcement scope; the counter may remain for display only.
- [A classification tag is converted into an access tag] → ownership does not bypass permission; test that its creator loses assignment ability unless one of their groups holds the permission.
- [A request or application save tries to disable admin-group permission] → reject disable requests and enforce the true invariant in the group model; the UI has no editable toggle. Direct SQL and callback/validation-bypassing writes must preserve this invariant; defaults alone do not protect updates.
- [Additional queries for manageability] → use database scopes rather than per-tag permission queries; the current controllers construct scopes separately for the diff and UI, with no request-level memoization guarantee.
- [Non-admin users lose manual access-tag management on deploy] → administrators must explicitly enable it for groups responsible for distributing mail. This is intentional; classification-tag editing, signing and automated assignments remain unaffected.

## Migration Plan

The migration adds `groups.can_manage_access_tags` (boolean, default false, not null) and sets it to true only for existing admin groups. Existing and new non-admin groups require an explicit grant. New admin groups default to true and ordinary application saves cannot disable it. Administrators should grant the permission to mail-distribution groups after deployment. Rolling back the migration removes the column.

## Open Questions

- None.
