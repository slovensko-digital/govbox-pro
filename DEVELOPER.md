# GovBox Pro

## Requirements

- [asdf version manager](https://asdf-vm.com/)
- `docker` with `docker-compose`

## Installation steps

### Install Ruby and Node.js to versions specified in [.tool-versions](.tool-versions)

Ensure to have `postgresql-devel` and `libyaml-devel` installed in your system.

```console
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install
```

## Configuration

Create own env file `

```console
cp .env .env.local
```

Setup an email with which you will sign in in `.env.local`

```dotenv
SITE_ADMIN_EMAILS=your-g-suite-sign-up-email@gmail.com
```

### Google OAuth2

- [Get / Create OAuth permissions by guide](https://medium.com/@jenn.leigh.hansen/google-oauth2-for-rails-ba1bcfd1b863)
  - don't forget to Add an Authorized Redirect URI `http://localhost:3000/auth/google_oauth2/callback`
- write permissions to `.env.local`, example:

```dotenv
GOOGLE_CLIENT_ID=some-numbers-and-characters.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-and-other-secret-part
```

### Microsoft Entra ID (AAD)

- [Create AAD APP](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
  - don't forget to Add a Redirect URI `http://localhost:3000/auth/microsoft_graph/callback`
- write `Application (client) ID` and `Certificates & secrets` to `.env.local`, example:

```dotenv
AZURE_APPLICATION_CLIENT_ID=some-numbers-and-characters
AZURE_APPLICATION_CLIENT_SECRET=some-secret
```

- in the portal, open the Manifest tab under Manage section and set the following properties:

```json
"accessTokenAcceptedVersion": 2,
"signInAudience": "AzureADandPersonalMicrosoftAccount"
```

> For more details, see the [official documentation](https://learn.microsoft.com/en-us/entra/identity-platform/reference-app-manifest#signinaudience-attribute)

## Running

### Run database

```console
docker-compose up
```

### Install dependencies & setup database for local and test environment

```console
./bin/setup --skip-server
env RAILS_ENV=test ./bin/setup --skip-server
npm install
```

### Seed the database

After configuring your admin email and setting up the database, run:

```console
./bin/rails db:seed
```

> [!NOTE]
> Make sure you have set `SITE_ADMIN_EMAILS` in your `.env.local` file before running the seed command, as this creates the admin account and other initial data.

### Run local development environment

```console
./bin/dev
```

### Run tests

```console
./bin/rails test
```

### Isolated test databases

Use a dedicated PostgreSQL database when testing parallel worktrees. Set
`DATABASE_URL` to your local server with a unique database name and set
`RAILS_ENV=test` for every setup, migration, test, and test-server command.
Verify the resolved database before schema operations. Never reset the shared
`govbox_pro_test` while another checkout is using it.

### Personalized filter operations

Common publication distributes preferences in batches of 100 users. Existing
pins, order, and explicit unpins are retained. A retry is safe:

```ruby
Filter.find(common_filter_id).distribute!
```

User initialization uses the same idempotent path:

```ruby
User.find(user_id).initialize_filter_preferences!
```

Neither operation belongs in a GET request. Menu reads resolve personal query
precedence before selecting existing pins and do not create preferences. The
`:personalized_filters` tenant feature controls switching navigation reads; keep
it disabled until the existing-data backfill and checks have completed.

### Personalized filter deployment and recovery

1. Take a database backup and save an audit of existing filter IDs, tenant/author
   IDs, query/name/order, and complete subscription rows (especially event types,
   filter IDs, and `last_notify_run_at`). Use a production-like copy for rehearsal.
   Temporarily pause filter-definition writes during schema preparation/cutover.
2. If not yet applied, run the additive scope migration with the deployment's
   database environment: `bin/rails db:migrate:up VERSION=20261022180000`.
   Existing tenant-visible rows become common without changing their IDs.
3. Run `bin/rails filters:preflight`. An empty JSON array means no query collisions.
   A failure reports filter IDs and subscriber counts; resolve that data explicitly
   before proceeding. Do not merge subscription events or move checkpoints merely
   to make the migration pass. The uniqueness migration also enforces this check.
4. Run `bin/rails db:migrate`. The backfill snapshots the legacy menu once in
   `tenants.settings["personal_filter_navigation_seed_ids"]`, creates missing
   all-messages/visible-tag query shortcuts, and seeds preferences in user batches.
   It does not create personal copies or remap subscriptions. Verify original
   filter IDs/attribution and complete subscription rows against the audit.
5. Run `bin/rails filters:backfill_navigation` again to reconcile users created
   during deployment. Retrying is safe: existing preferences, explicit unpins,
   order, subscription IDs, and checkpoints remain unchanged. Later-created tags
   are not added to the stored legacy snapshot.
6. Verify each user's initial first query is empty, old query links still work,
   and query/subscription controls are available for unpinned filters. Enable
   reads per tenant only after those checks:

   ```ruby
   Tenant.find(tenant_id).enable_feature(:personalized_filters, force: true)
   ```

7. If distribution was interrupted after publishing a common filter, retry
   `Filter.find(filter_id).distribute!`. User onboarding can likewise retry
   `User.find(user_id).initialize_filter_preferences!`; neither resets choices.

For a read-path rollback, disable only the feature:

```ruby
Tenant.find(tenant_id).disable_feature(:personalized_filters, force: true)
```

This retains all new data and returns the legacy navigation layout. It does not
restore old definition-editing permissions or expose personal filters to other
users. Prefer a forward fix; do not run destructive down migrations or resurrect
cancelled subscriptions. Restore from the deployment backup only through an
explicit operational decision. Standard notification foreign keys continue to
cascade source-linked history on subscription removal; unrelated notifications,
messages, and threads remain intact.

Fixture rehearsal on current main (`c436c394`), 2026-10-23, using a separate local
database: 4 existing filters became 56 common query shortcuts; 1 subscription
remained the identical row, including its checkpoint; 257 preferences were seeded
and the basic user's 26 pins began with the empty query. A second backfill retained
the same counts. Enabling/disabling the read feature preserved preferences.

Integrated filter verification (Ruby 4.0.6 / Rails 8.1.4, dedicated test database,
after `bin/rails tailwindcss:build`):

```console
bin/rails test test/models/*filter*test.rb test/policies/filter_policy_test.rb test/components/filter_list_component_test.rb test/controllers/filters_controller_test.rb test/controllers/common_filters_controller_test.rb test/controllers/filter_subscriptions_controller_test.rb test/controllers/boxes_filter_context_test.rb test/controllers/settings/user_filter_visibilities_controller_test.rb test/controllers/message_threads/filter_query_test.rb test/jobs/notify_filter_subscription_job_test.rb test/system/filters_test.rb test/system/personalized_filters_test.rb test/system/common_filters_test.rb test/system/filter_acceptance_test.rb test/system/message_threads_test.rb test/system/notifications_test.rb
```

Run with `RAILS_ENV=test` and `DATABASE_URL` explicitly selecting the dedicated
database. Result on 2026-10-23, seed 5858: **86 tests, 545 assertions, zero failures,
errors, or skips**. Shared-filter journeys explicitly classify their fixture as
common; the logout helper waits for the dropdown's initial close animation
instead of using retry clicks or weakening assertions.

Final verification adds `test/system/filter_acceptance_test.rb` and personalized
system-tag navigation coverage to that command: seed 42603, **88 tests, 631
assertions, zero failures, errors, or skips**.
The acceptance journey covers an administrator and two users, independent default
ordering, clear search, publication into pinned/unpinned personal matches,
subscription management under a personal title, authorized delivery, unpinned
notification links, original common-order restoration, confirmed query edits,
and cancelled/confirmed deletion with two subscribers.
The personalized sidebar also keeps visible system-status shortcuts without
duplicating matching pinned definitions and shows signer-specific shortcuts only
to their owner; these shortcuts do not create saved filters.
To capture browser evidence, set `FILTER_DEMO_DIRECTORY` to an existing directory
and run `bin/rails test test/system/common_filters_test.rb test/system/filter_acceptance_test.rb`.
The tests save query confirmation, subscriber warnings, personal notification
context, and independent common-default screenshots there.

The final diff was checked against PR #249 as context only: no STI filter types,
sortable dependency, `filter_id` message-list navigation, permanent tag callbacks,
group/template distribution, tag-rename rewriting, notification query versions,
display-precedence delivery suppression, or migration subscription remapping.
`openspec validate personalize-query-filters --strict` and `git diff --check` pass.

### Run console

```console
./bin/rails c
```

## API

### OpenAPI Documentation

[public/openapi.yaml](public/openapi.yaml)

### Setup API credentials for development

1. Generate RSA keypair:

```console
openssl genrsa -out govbox_dev_api_token.private.pem 2048
openssl rsa -in govbox_dev_api_token.private.pem -pubout -out govbox_dev_api_token.public.pem
```

2. Set the public key on your tenant, enable API feature, Generate API token (in Rails console):

```rb
# bin/rails console

TENANT_ID = 1 # your tenant id
PEM = 'govbox_dev_api_token.private.pem'

tenant = Tenant.find(TENANT_ID)
tenant.api_token_public_key = File.read(PEM)
tenant.feature_flags << :api
tenant.save!

def api_token_private_key
  OpenSSL::PKey::RSA.new(File.read(PEM))
end

def generate_api_token(tenant)
  JWT.encode({ sub: tenant.id, exp: 5.minutes.from_now.to_i, jti: SecureRandom.uuid }, api_token_private_key, 'RS256')
end

token = generate_api_token(tenant) # max 5 minutes validity
```

3. Use the token in API requests:

```console
export GOVBOX_TOKEN=token-from-rails-console
curl -H "Authorization: Bearer $GOVBOX_TOKEN" http://localhost:3000/api/boxes
```

## Other

### Async Jobs

- We use [Good Jobs](https://github.com/bensheldon/good_job)
- See [jobs web ui / dashboard](http://localhost:3000/good_job)

### Getting sample data

- Your public IP has to be added to whitelist (ask colleague)
- In rails console run `Govbox::SyncBoxJob.perform_later(Box.last)`

### Create sample FS connections

Execute [this script](https://gist.github.com/luciajanikova/a9ab34c7d4ca886777d130e34baf1617#file-seed_boxes-rb) in rail console.

### Create sample UPVS connection

Execute following command in rails console.

```rb
Govbox::ApiConnectionWithOboSupport.find_or_create_by!(
  tenant: Tenant.first,
  sub: "SPL_Irvin_83300252_KK_24022023",
  api_token_private_key: File.read(Rails.root + "security/govbox_api_fix.pem")
)
```
