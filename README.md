# bonny_plug - Kubernetes Admission Webooks Plug

[![Build Status](https://github.com/ufirstgroup/bonny_plug/workflows/CI/badge.svg)](https://github.com/ufirstgroup/bonny_plug/actions?query=workflow%3ACI)
[![Coverage Status](https://codecov.io/gh/ufirstgroup/bonny_plug/branch/master/graph/badge.svg)](https://codecov.io/gh/ufirstgroup/bonny_plug)
[![Hex.pm](http://img.shields.io/hexpm/v/bonny_plug.svg?style=flat&logo=elixir)](https://hex.pm/packages/bonny_plug)
[![Documentation](https://img.shields.io/badge/documentation-on%20hexdocs-green.svg)](https://hexdocs.pm/bonny_plug/)
![Hex.pm](https://img.shields.io/hexpm/l/bonny_plug.svg?style=flat)

`bonny_plug` aims to extend the Kubernetes development framework [Bonny](https://github.com/coryodaniel/bonny) with admission hooks. However, the library can
be used on its own and has no dependencies to Bonny.

## Installation

```elixir
def deps do
  [
    {:bonny_plug, "~> 1.0"}
  ]
end
```

## Usage

### Plug

Add the plug to a Phoenix or Plug router to forward admission webhook requests to the handlers. You have to pass the
`webhook_type` and the list of `handlers` to the plug. See below for ways to implement webhook handlers.

```elixir
post "/admission-review/validate", BonnyPlug.WebhookPlug,
  webhook_type: :validating_webhook,
  handlers: [MyApp.WebhookHandlers.FooResourceWebhookHandler]

post "/admission-review/mutate", BonnyPlug.WebhookPlug,
  webhook_type: :mutating_webhook,
  handlers: [MyApp.WebhookHandlers.FooResourceWebhookHandler]
```

### Webhook Handlers

You're gonna want to write code that validates/mutates incoming admission webhook requests. You do this by writing
webhook handlers and passing them via the `handlers` options to the `WebhookPlug` as described above. There are more
and less explicit ways to implement a webhook handler.

#### Using `BonnyPlug.WebhookHandler` with CRDs

The simplest way if you are working with Custom Resource Definitions is to `use BonnyPlug.WebhookHandler` in your
webhook handler and tell it where to find your CRD YAML file. `BonnyPlug.WebhookHandler` will then extract all
necessary information from the YAML file and forward matching calls to your request handlers.

Your webhook handler now has to implement at least one of the two possible request handler functions
`validating_webhook/1` and `mutating_webhook/1`. Both take a struct `%BonnyPlug.AdmissionReview{}` as argument, operate
on it and return it.

`use BonnyPlug.WebhookHandler` imports `BonnyPlug.AdmissionReview.Request` so you have helper functions like `allow/1`,
`deny/1`, `check_immutable/2`, etc. available in your request handlers.

```elixir
defmodule FooAdmissionWebhookHandler do
  use BonnyPlug.WebhookHandler, crd: "manifest/src/crds/foo.crd.yaml"

  @impl true
  def validating_webhook(admission_review)  do
    check_immutable(admission_review, ["spec", "someField"])
  end

  @impl true
  def mutating_webhook(admission_review)  do
    allow(admission_review)
  end
end
```

#### Using `BonnyPlug.WebhookHandler` with other Resources

If for some reason you want to add webhooks to other resources, you can `use BonnyPlug.WebhookHandler` and pass it the
necessary information about the resource. These are its group, the supported api_versions and its plural resource name.

```elixir
defmodule BarAdmissionWebhookHandler do
  use BonnyPlug.WebhookHandler,
    group: "my.operator.com",
    api_versions: ["v1"],
    resource: "barresources"

  @impl true
  def validating_webhook(admission_review)  do
    check_immutable(admission_review, ["spec", "someField"])
  end

  @impl true
  def mutating_webhook(admission_review)  do
    deny(admission_review)
  end
end
```

#### Explicit Implementation of a Webhook Handler

If you don't like the magic of `use` and macros, feel free to implement the full handler yourself. It should implement
the behaviour `@behaviour BonnyPlug.WebhookHandler` and therefore the function `process/2`. Note that `process/2` is
called for every request so you have check whether your handler has to handle it or not.

```elixir
defmodule ExplicitAdmissionWebhookHandler do
  @behaviour BonnyPlug.WebhookHandler

  alias BonnyPlug.AdmissionReview
  alias BonnyPlug.AdmissionReview.Request

  @impl true
  def process(%AdmissionReview{request: %{"..." => ""}} = admission_review, :validating_webhook) do
    Request.check_immutable(admission_review, ["spec", "someField"])
  end
  def process(ignored_request), do: ignored_request
end
```

