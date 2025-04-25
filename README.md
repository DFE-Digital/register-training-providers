# Register of training providers
The service for managing the canonical list of training providers for Department for Education (DfE) and, more specifically, Becoming a teacher (BAT).

## Setup

### Prerequisites

This project depends on:

  - [Ruby](https://www.ruby-lang.org/)
  - [Ruby on Rails](https://rubyonrails.org/)
  - [NodeJS](https://nodejs.org/)
  - [Yarn](https://yarnpkg.com/)
  - [Postgres](https://www.postgresql.org/)

### asdf

This project uses `asdf`, refer to [.tool-versions](.tool-versions) for the actual versions in use. Use the following to install the required tools:

```sh
# The first time
brew install asdf # Mac-specific
asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add yarn
asdf plugin add postgres

# To install (or update, following a change to .tool-versions)
asdf install
```

When installing the `pg` gem, bundle changes directory outside of this
project directory, causing it lose track of which version of postgres has
been selected in the project's `.tool-versions` file. To ensure the `pg` gem
installs correctly, you'll want to set the version of postgres that `asdf`
will use:

```sh
# Temporarily set the version of postgres to use to build the pg gem
ASDF_POSTGRES_VERSION=17.2 bundle install
```

### Intellisense

[solargraph](https://github.com/castwide/solargraph) is bundled as part of the
development dependencies. You need to [set it up for your
editor](https://github.com/castwide/solargraph#using-solargraph), and then run
this command to index your local bundle (re-run if/when we install new
dependencies and you want completion):

```sh
bin/bundle exec yard gems
```

You'll also need to configure your editor's `solargraph` plugin to
`useBundler`:

```diff
+  "solargraph.useBundler": true,
```
## How the application works

We keep track of architecture decisions in [Architecture Decision Records
(ADRs)](/adr/).

We use `rladr` to generate the boilerplate for new records:

```bash
bin/bundle exec rladr new title
```

### Running the app

To run the application locally:

1. Run `bin/setup --skip-server` to setup the app
2. Run `bin/dev` to launch the app on <http://localhost:1025>
