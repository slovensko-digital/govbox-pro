# Verification

## Review verification (2026-10-13)

The review implementation at commit `f781d720` was tested in this review worktree with the isolated Docker PostgreSQL database `DATABASE_URL=postgres://postgres:postgres@127.0.0.1:55432/govbox_access_review_test` and `RAILS_ENV=test`. No `.env` changes were made.

```sh
bin/rails test test/models/admin_group_test.rb test/models/access_tag_permission_migration_test.rb test/models/user_access_tag_permission_test.rb test/models/tag_test.rb test/models/relation_changes_tags_test.rb test/policies/admin/group_policy_test.rb test/policies/message_thread_policy_test.rb test/controllers/admin/groups_controller_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb test/system/access_tag_permissions_test.rb test/models/automation test/jobs/automation test/jobs/fs test/jobs/govbox test/system/message_threads_bulk_sign_test.rb test/system/message_drafts_signing_test.rb
```

Result: **161 tests, 652 assertions, no failures, errors or skips**.

- The list template delegates manageability to `TagsAssignment::ListComponent#manageable?(tag)`.
- The new permission update uses Rails boolean casting and `Group` inclusion validation, with 422 rendering on validation failure. The pre-existing `all_boxes_permission` action is unchanged.
- `Tag#manageable_by?` was unused in production and removed; the tests exercise the enforcement scope instead, retaining ownership and stale-counter coverage.
- The policy and permissions form use polymorphic `manage_access_tags_changable?` for admin-group immutability.
- Locked tags use the tooltip "Tento štítok nemáte právo meniť".
- Chrome tests navigate through the permissions list and revoke access-tag management for `AllGroup`, `UserGroup` and `SignerGroup`. A model regression verifies that permission granted to existing groups can be fully revoked for a non-admin by disabling every granting membership.

### Submission verification after review

Additional controller and Chrome regressions were run in the same isolated database:

```sh
bin/rails test test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb test/system/access_tag_permissions_test.rb
```

Result: **33 tests, 251 assertions, no failures, errors or skips**.

- Single-thread and two-thread bulk dialogs were submitted after changing the editable Print classification tag. Finance and Legal access tags were disabled, clicking their checkboxes did not change their values or checked state, and no named assignment input existed for either locked tag.
- After saving, the database retained each thread's original locked assignments and applied the permitted Print assignment. In bulk, Legal was assigned to only one thread and its mixed state remained intact.
- A mixed two-thread controller request attempted to remove a locked access tag while adding Print and an invalid ID. The locked assignment remained on both threads, Print was added, and the response succeeded. Existing single/bulk controller regressions also reject additions and removals of owned access tags without permission.

The combined command above, including the additional submission regressions, passed with `--seed 56568`: **164 tests, 701 assertions, no failures, errors or skips**. This is the latest successful combined run; the seed-specific signing interaction below remains a verification caveat.

The combined command above was also run with the additional submission regressions and `--seed 51235`: **164 tests, 694 assertions, one failure**, reproduced on a second run with the same seed. `MessageDraftsSigningTest#test_user_can_request_a_signature_from_a_user_on_message_drafts` failed at line 16 because the "Vyžiadať podpis" link was not visible. The isolated signing file with that seed passed: **2 tests, 18 assertions, no failures or errors**. The successful submission-focused run is not evidence that the combined suite is consistently green.

Baseline comparison used a detached worktree at `f781d720`, before the additional submission tests and documentation updates, with a separate `govbox_access_review_baseline_test` database on the same PostgreSQL port. The same combined command and seed produced **161 tests, 645 assertions, one error** in that signing test: Selenium `ElementNotInteractableError` when clicking the signature-request link at line 17. This demonstrates that the signing-menu interaction problem exists without the new submission regressions; it does not establish the root cause or compare this PR against `main`. No signing implementation or test was modified to hide the failure.

### Specification and archive consistency

The main specification was compared with the assignment scopes, thread visibility policy, group models and policy, migrations, single/bulk controllers, rendered inputs and regression tests. Review refactors do not change the behavior contract, so the main specification and archived delta were left unchanged. They match exactly after replacing the delta title and `ADDED Requirements` header with their main-spec equivalents.

```sh
openspec validate --specs --strict --json
openspec validate --archived --strict --json
```

Both passed with no findings. Spec validation covers the main `access-tags` specification; archived validation confirms all twelve tracked tasks are complete. `openspec list --json` returns no active changes. No new change was created and no archive operation was repeated.

### List query measurement and optimization

SQL instrumentation used `sql.active_record` with the query cache disabled, excluding schema and transaction events. For both 1 and 100 visible tags, before optimization the list performed 2 preparation queries plus 1 render query; repeating `manageable?` ten times for every tag performed 0 queries. `manageable_ids` was already stored as a `Set`, not a lazy relation or a repeated `pluck`.

After optimization, the same measurements were 2 preparation queries, 0 render queries and 0 repeated-predicate queries. These counts cover `TagsFilter` construction and list rendering after the tag scopes are built; they are not counts for the entire controller request or its group-permission lookup. Non-empty search retains 3 list queries to preserve database accent/case-insensitive matching. Without a separate manageable scope, an empty-search list uses 1 query.

The component now prepares the locked assignment hash once and builds checkboxes through `checkbox_for`. For a locked tag, both `init` and `new` refer to the original `init` assignment values, preserving checked and mixed states even when new values are absent or tampered with. Manageable tags continue to render their edited state. This hash is only read for rendering and does not assign tags in the database.

```sh
bin/rails test test/components/tags_assignment/list_component_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb test/system/access_tag_permissions_test.rb
```

Result: **38 tests, 270 assertions, no failures, errors or skips**. Includes fixed query counts for 1 and 100 tags, zero-query repeated membership checks, accent/case-insensitive search, initial locked versus edited manageable state, mixed locked state, and the single/bulk submission regressions.

Coverage limits remain unchanged: these are local browser and mocked service/job tests, not live FS/UPVS integrations or a new run of the entire application suite.

## Historical verification at original archive

The results below are retained as the original archive record, not the current review counts. These commands ran in the original implementation worktree using the isolated Docker PostgreSQL database `DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/govbox_pro_access_tags_test`. No `.env` changes were made.

### Browser checks

`bin/rails test test/system/access_tag_permissions_test.rb`: 5 tests, 67 assertions, no failures or errors (headless Chrome).

- Single-thread and two-thread bulk assignment were checked for regular users and users granted the group permission.
- Assigned locked tags stayed checked after editing a classification tag and filtering the list away and back. Locked tags submitted no new assignment value.
- Manageable tags remained editable, including access tags for permission holders.
- The admin group's page displayed localized `Vždy povolené` without a permission toggle.
- The first run exposed a locked-tag display regression after search: absent submitted values appeared unchecked. The locked checkbox now renders its original assignment state, without changing the diff or submitting a new value. The regression test passes.

An earlier `bin/rails test:system ...` invocation unexpectedly ran the entire system suite: 85 tests, 591 assertions, one failure in `MessageThreadsBulkExportTest#test_setting_od_date_in_future_excludes_current_messages_from_preview`. This export date-filter failure is outside this change; the focused browser suite above passed.

### Combined model, policy and controller checks

```sh
bin/rails test test/models/admin_group_test.rb test/models/access_tag_permission_migration_test.rb test/models/user_access_tag_permission_test.rb test/models/tag_test.rb test/models/relation_changes_tags_test.rb test/policies/admin/group_policy_test.rb test/policies/message_thread_policy_test.rb test/controllers/admin/groups_controller_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb
```

Result: 53 tests, 170 assertions, no failures, errors or skips. Includes original migration up/down and admin repair up/down coverage.

### Exempt assignment paths

```sh
bin/rails test test/models/automation test/jobs/automation test/jobs/fs test/jobs/govbox test/system/message_threads_bulk_sign_test.rb test/system/message_drafts_signing_test.rb
```

Result: 84 tests, 333 assertions, no failures, errors or skips.

Code inspection confirmed that `manageable_scope` / `manageable_by` are used only by the ordinary single/bulk tag controllers, their diff and list filtering. No assignment callbacks were added.

- Signature requests continue to use `RelationChanges::Signers` and `MessageObject#add_signature_requested_from_group`; signing assigns/removes its tags directly.
- Automation add/remove actions use the thread association or `unassign_tag` directly, including signature-request-from-author actions.
- FS period tags use `thread.assign_tag`; FS validation and submission tests cover signature-request, submitted, draft and error tags.
- GovBox/UPVS processing continues through existing message/thread tag APIs; delivery-notification removal regression tests passed.

Coverage limits: these are existing mocked service/job and browser regression tests, not live FS/UPVS integrations. They do not exercise every exempt path under every permission combination. The exemption is additionally verified by inspecting scope call sites and the absence of permission checks in shared assignment APIs.

### Review fixes

The implementation review reproduced two additional edge cases, both now fixed:

- When all visible ordinary tags are locked, the form sends no `new` assignments. `RelationChanges::Tags` now normalizes that missing hash to an empty hash. Single and two-thread bulk search controller regressions pass; a model regression also checks that creating a new classification tag still works from this state.
- A locked tag assigned to only one selected thread must render as indeterminate, not fully checked. The disabled checkbox now uses the existing tri-state controller's initialization without a click action or assignment name. A Chrome regression checks the mixed state both before and after filtering the list away and back.

Focused command:

```sh
bin/rails test test/models/relation_changes_tags_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb test/system/access_tag_permissions_test.rb
```

Result: 29 tests, 189 assertions, no failures or errors.

The combined model/policy/controller, browser, automation, FS/GovBox and signing suites listed above were then run together against the original archived revision: 146 tests, 595 assertions, no failures, errors or skips. The review verification above supersedes these counts for the current implementation.
