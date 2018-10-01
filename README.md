# concourse-summary

Ever wanted to have a quick overview of all of your [concourse](https://concourse-ci.org) pipelines and groups? Then **Concourse Summary** is for you.

See an example at [concourse-summary-crystal.cfapps.io](https://concourse-summary-crystal.cfapps.io/)

### Usage

As this app is written in [crystal](https://crystal-lang.org/) it can be run in a number of ways:

#### Using crystal run

```
shards install
crystal run src/concourse-summary.cr
```

#### As a binary

```
shards install
crystal build --release src/concourse-summary.cr
```

#### As a CF app

You may want to modify the example `manifest.yml` file prior to running your CF push

```
cf push
```

All configuration is managed using environment variables:

| Variable            | Description                                                                               | Example                                                                                                                                                                          |
| ------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| HOSTS               | A space seperate list of all concourse hosts that you wish to have a dashboard for        | ci.concourse.ci appdog.ci.cf-app.com buildpacks.ci.cf-app.com diego.ci.cf-app.com capi.ci.cf-app.com                                                                             |
| CS_GROUPS           | A json string of a chosen group name, linking to a host, pipeline and groups in concourse | '{"test":{"buildpacks.ci.cf-app.com":{"binary-builder":["automated-builds","manual-builds"],"brats":null},"diego.ci.cf-app.com":{"greenhouse":null},"capi.ci.cf-app.com":null}}' |
| SKIP_SSL_VALIDATION | If set to "true" then SSL Validation will be ignored for all hosts                        | "true"                                                                                                                                                                           |
| REFRESH_INTERVAL    | An integer in seconds for configuring the page refresh interval, defaults to 30           | 10                                                                                                                                                                               |

## Query parameters for running instance

### Labels

Labels can filter the returned statuses to only those with the requested name as a substring of either the pipeline name or group name

eg: [labels=ruby](https://concourse-summary-crystal.cfapps.io/host/buildpacks.ci.cf-app.com?labels=ruby)

### Giphy

Sets giphy backgrounds on green images to make it easier to spot fully green (and reward you for it)

eg: [giphy=dog](https://concourse-summary-crystal.cfapps.io/host/buildpacks.ci.cf-app.com?giphy=dog)
