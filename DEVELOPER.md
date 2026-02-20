# GovBox Pro

## Requirements

- [asdf version manager](https://asdf-vm.com/)
- `docker` with `docker-compose`

## Instalation steps

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
./bin/setup
env RAILS_ENV=test ././bin/setup
yarn
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

### Run console

```console
./bin/rails c
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
