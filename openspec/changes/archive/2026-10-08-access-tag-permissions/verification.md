# Verification

All commands below ran in this worktree using the isolated Docker PostgreSQL database, with `DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/govbox_pro_access_tags_test`. No `.env` changes were made.

## Browser checks

`bin/rails test test/system/access_tag_permissions_test.rb`: 5 tests, 67 assertions, no failures or errors (headless Chrome).

- Single-thread and two-thread bulk assignment were checked for regular users and users granted the group permission.
- Assigned locked tags stayed checked after editing a classification tag and filtering the list away and back. Locked tags submitted no new assignment value.
- Manageable tags remained editable, including access tags for permission holders.
- The admin group's page displayed localized `Vždy povolené` without a permission toggle.
- The first run exposed a locked-tag display regression after search: absent submitted values appeared unchecked. The locked checkbox now renders its original assignment state, without changing the diff or submitting a new value. The regression test passes.

An earlier `bin/rails test:system ...` invocation unexpectedly ran the entire system suite: 85 tests, 591 assertions, one failure in `MessageThreadsBulkExportTest#test_setting_od_date_in_future_excludes_current_messages_from_preview`. This export date-filter failure is outside this change; the focused browser suite above passed.

## Combined model, policy and controller checks

```sh
bin/rails test test/models/admin_group_test.rb test/models/access_tag_permission_migration_test.rb test/models/user_access_tag_permission_test.rb test/models/tag_test.rb test/models/relation_changes_tags_test.rb test/policies/admin/group_policy_test.rb test/policies/message_thread_policy_test.rb test/controllers/admin/groups_controller_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb
```

Result: 53 tests, 170 assertions, no failures, errors or skips. Includes original migration up/down and admin repair up/down coverage.

## Exempt assignment paths

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

## Review fixes

The implementation review reproduced two additional edge cases, both now fixed:

- When all visible ordinary tags are locked, the form sends no `new` assignments. `RelationChanges::Tags` now normalizes that missing hash to an empty hash. Single and two-thread bulk search controller regressions pass; a model regression also checks that creating a new classification tag still works from this state.
- A locked tag assigned to only one selected thread must render as indeterminate, not fully checked. The disabled checkbox now uses the existing tri-state controller's initialization without a click action or assignment name. A Chrome regression checks the mixed state both before and after filtering the list away and back.

Focused command:

```sh
bin/rails test test/models/relation_changes_tags_test.rb test/controllers/message_threads/tags_controller_test.rb test/controllers/message_threads/bulk/tags_controller_test.rb test/system/access_tag_permissions_test.rb
```

Result: 29 tests, 189 assertions, no failures or errors.

The combined model/policy/controller, browser, automation, FS/GovBox and signing suites listed above were then run together against the final code: 146 tests, 595 assertions, no failures, errors or skips.
