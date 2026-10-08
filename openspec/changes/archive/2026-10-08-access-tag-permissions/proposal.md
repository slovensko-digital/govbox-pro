# Proposal

## Why

Visible ordinary tags serve two purposes: classification (no assigned groups, e.g. "Print") and granting thread access to assigned groups (e.g. "Finance"). Thread visibility requires access to its box and membership in a group linked to at least one tag on the thread; multiple access tags grant alternative access paths. Before this change, anyone who could see a thread could change its ordinary access-tag assignments and thereby change who could see it.

## What Changes

- Introduce a group-level permission `can_manage_access_tags` that lets a non-admin user manage access tags.
- Enforce tag manageability when tags are assigned to or removed from a thread, both for a single thread and in bulk: the server ignores changes to tags the user may not manage.
- Do not exempt a tag's creator or owner from access-tag assignment permission. Classification tags remain editable without that permission, even after creation by an ordinary user.
- Keep the tenant's visible ordinary tags in the assignment list, but show tags the user may not manage as locked (disabled) and send no change for them.
- Add an admin-only toggle for non-admin groups. The admin group always has the stored permission enabled; show a localized "Always enabled" status and reject attempts to disable it. Evaluate user permission uniformly through group membership, without an admin bypass.
- Grandfather existing groups on deploy so current behavior does not break. New non-admin groups default to false; new admin groups default to true, and existing admin groups with false are repaired to true.
- Limit enforcement to manual single and bulk assignment of visible ordinary tags. Signature-request tags and automation / FS / UPVS assignments remain unaffected.
- Keep thread visibility unchanged: access-tag management does not itself grant access to threads or boxes.

## Capabilities

### New Capabilities
- `access-tags`: how classification and access tags differ, who may manage a tag assignment on a thread, and the group permission that grants it.

### Modified Capabilities
<!-- No existing specs yet; this is the first capability. -->

## Impact

- Models: `Tag`, `User`, `Group` / `AdminGroup`, `TagsFilter`, `RelationChanges`.
- Controllers: `MessageThreads::TagsController`, `MessageThreads::Bulk::TagsController`, `Admin::GroupsController`.
- Views/components: `tags_assignment/list_component`, `admin/permissions/_group_form`.
- Policy: `Admin::GroupPolicy`.
- Database: `groups.can_manage_access_tags` column plus migration/backfill.
