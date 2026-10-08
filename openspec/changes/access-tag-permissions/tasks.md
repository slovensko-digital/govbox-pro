# Tasks

Existing implementation below includes upstream commit `e6680b74`, not a test run in this worktree. Plain bullets record existing work; unchecked tasks cover remaining implementation or verification. Do not recreate existing code.

## 1. Group permission

Already implemented:
- Boolean column with false default, non-null constraint and migration backfilling existing groups to true.
- `User#can_manage_access_tags?` uses group permission lookup without an admin bypass; tenant creation grants the admin group true and fixtures reflect it. Basic model tests exist.
- Admin-only route, policy, controller action and toggle for groups; basic policy/controller tests exist.

- [x] 1.1 Verify the migration in an isolated test database: pre-existing groups become true, new groups have a false stored default, and rollback removes the column; add focused migration coverage.
- [x] 1.2 Guarantee the stored-true invariant for admin groups: default new admin groups to true for all ordinary creation paths, reject application saves with false, and add a follow-up migration repairing existing false admin-group values without changing non-admin permissions. Add and run model and isolated repair-migration tests; retain the uniform group-based user lookup without an admin bypass.
- [x] 1.3 Show a localized "Always enabled" status without an editable toggle for the admin group; add and run a rendering test against a valid admin group with stored permission true.
- [x] 1.4 Reject admin-group disable requests while preserving valid non-admin-group updates; add and run policy/controller tests for rejection, non-admin denial and valid updates.

## 2. Server-side enforcement

Already implemented:
- Assignment ids resolve with `where(id: ids)` rather than `find`.
- `RelationChanges::Tags` filters its diff through a manageable scope.
- Single and bulk controllers pass that scope in edit, prepare, create and update.
- The enforcement scope uses actual tag-group associations via NOT EXISTS; the instance predicate still calls the counter-based display predicate `gives_access?`. Basic permission tests and an owned-tag duplicate-row test exist.

- [x] 2.1 Remove the ownership exemption from the manageable scope and predicate while retaining uniform group-permission lookup without an admin bypass. Use actual group associations for ordinary-tag manageability, including the predicate; replace existing owner-allowing tests with owner-denial tests and add stale-zero-counter coverage. Verify an owned access tag with several groups is excluded without permission and returned once with permission; run the model tests.
- [x] 2.2 Add and run focused diff/controller tests verifying out-of-scope ids are ignored and a mixed request applies permitted changes while retaining locked assignments.
- [x] 2.3 Add and run single and bulk tests rejecting both addition and removal of an owned access tag without permission, plus coverage that a creator can assign their classification tag but cannot assign it after groups are attached. Select at least two threads in bulk tests; retain permission-holder and admin cases.
- [x] 2.4 Add and run regression tests for thread access prerequisites: box access plus a matching tag group, alternative access through multiple tags, and no visibility grant from management permission alone.

## 3. UI show-but-locked

Already implemented:
- Disabled unnamed checkboxes, no hidden assignment field, non-clickable labels and translated tooltip for locked tags.
- Rendering assertions exist for single and bulk edit responses.

- [x] 3.1 Run existing rendering tests and add focused assertions for the tooltip and exclusion of hidden/system tags from the ordinary assignment list.
- [x] 3.2 Inspect the single and multi-thread assignment UI for regular and permission-holding users; verify locked tags retain their displayed assignment state through search/prepare, manageable tags remain editable, and the admin-group setting shows a localized "Always enabled" status. Record observed results or the environment blocker.

## 4. Integration verification

- [x] 4.1 Run the relevant model, policy and controller suites together against the final code; record commands and outcomes without treating prior-worktree runs as verification of this worktree.
- [x] 4.2 Verify the unchanged signing and automation / FS / UPVS assignment paths do not receive the manageable scope; run relevant existing regression tests and record any coverage gaps.

## Workflow follow-up

- Archive the change after implementation and review are complete.
- Verify the archived behavior contract appears under `openspec/specs/access-tags/`.
