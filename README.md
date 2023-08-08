# GovBox Pro

## Requirements
- ruby (version is specified in [.tool-versions](.tool-versions))
  - [asdf version manager](https://asdf-vm.com/)
- PostgreSQL 14
- node.js (should not matter which version. worked on: `v15.8.0`, `v16.15.1`)

## Instalation steps

1. create own env file `cp .env .env.local`
2. setup db connection in `.env.local`, example:

```dotenv
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres
```
3. setup an email with which you will sign in in `.env.local`

```dotenv
SITE_ADMIN_EMAILS=your-g-suite-sign-up-email@gmail.com
```

4. install deps and setup database with `bin/setup`
5. install javascript deps with `yarn`

## Application Setup

### Google OAuth2
- [Get / Create OAuth permissions by guide](https://medium.com/@jenn.leigh.hansen/google-oauth2-for-rails-ba1bcfd1b863)
  - don't forget to Add an Authorized Redirect URI `http://localhost:3000/auth/google_oauth2/callback`
- write permissions to `.env.local`, example:

```dotenv
GOOGLE_CLIENT_ID=some-numbers-and-characters.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-and-other-secret-part
```

### Running commands

- run local environment `bin/dev`
- run tests with `bin/rails test`
- run console `bin/rails c`

### Async Jobs
- we use [Good Jobs](https://github.com/bensheldon/good_job)
- settings in env

```dotenv
ADMIN_IDS=1 # set your user_id be able to see dashboard
GOOD_JOB_EXECUTION_MODE=async # make job runs along rails server (default)
```

- [jobs web ui / dashboard](http://localhost:3000/good_job)

### Getting sample data
- your public IP has to be added to whitelist (ask colleague)
- in rails console run this `Govbox::SyncBoxJob.perform_later(Box.last)`
