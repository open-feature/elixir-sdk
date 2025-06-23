<!-- markdownlint-disable MD033 -->
<!-- x-hide-in-docs-start -->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/white/openfeature-horizontal-white.svg" />
    <img align="center" alt="OpenFeature Logo" src="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/black/openfeature-horizontal-black.svg" />
  </picture>
</p>

<h2 align="center">OpenFeature Elixir SDK</h2>

<!-- x-hide-in-docs-end -->
<!-- The 'github-badges' class is used in the docs -->
<p align="center" class="github-badges">
  <a href="https://github.com/open-feature/spec/releases/tag/v0.7.0">
    <img alt="Specification" src="https://img.shields.io/static/v1?label=specification&message=v0.7.0&color=yellow&style=for-the-badge" />
  </a>
  <!-- x-release-please-start-version -->

  <a href="https://github.com/open-feature/elixir-sdk/releases/tag/v0.1.2">
    <img alt="Release" src="https://img.shields.io/static/v1?label=release&message=v0.1.2&color=blue&style=for-the-badge" />
  </a>

  <!-- x-release-please-end -->
  <br/>
  <a href="https://hexdocs.pm/open_feature/">
    <img alt="Docs" src="https://img.shields.io/badge/docs-hexpm-blue.svg" />
  </a>
  <a href="https://github.com/open-feature/elixir-sdk/blob/main/LICENSE.md">
    <img alt="License" src="https://img.shields.io/hexpm/l/req.svg" />
  </a>
  <a href="https://github.com/open-feature/elixir-sdk/actions/workflows/ci.yml">
    <img alt="CI" src="https://github.com/open-feature/elixir-sdk/actions/workflows/ci.yml/badge.svg" />
  </a>
  <a href="https://bestpractices.coreinfrastructure.org/projects/6601">
    <img alt="CII Best Practices" src="https://bestpractices.coreinfrastructure.org/projects/6601/badge" />
  </a>
</p>
<!-- x-hide-in-docs-start -->

[OpenFeature](https://openfeature.dev) is an open specification that provides a vendor-agnostic, community-driven API for feature flagging that works with your favorite feature flag management tool or in-house solution.

<!-- x-hide-in-docs-end -->
## 🚀 Quick start

### Requirements

It requires Elixir 1.14 or greater to run.

### Install

The package can be installed by adding `open_feature` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:open_feature, "~> 0.1"}]
end
```

### Usage

```elixir
provider = %OpenFeature.Provider.InMemory{
  flags: %{
    "v2_enabled" => %{
      disabled: false,
      default_variant: "on",
      variants: %{
        "on" => true,
        "off" => false,
      }
    }
  }
}
{:ok, provider} = OpenFeature.set_provider(provider)
client = OpenFeature.get_client()
v2_enabled = OpenFeature.Client.get_boolean_value(client, "v2_enabled", false)
```

### API Reference

For details, including API documentation, see the respective [Hex docs](https://hexdocs.pm/open_feature/).

## 🌟 Features

| Status | Features                                                            | Description                                                                                                                                                  |
| ------ | --------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ✅      | [Providers](#providers)                                             | Integrate with a commercial, open source, or in-house feature management tool.                                                                               |
| ✅      | [Targeting](#targeting)                                             | Contextually-aware flag evaluation using [evaluation context](https://openfeature.dev/docs/reference/concepts/evaluation-context).                           |
| ✅      | [Hooks](#hooks)                                                     | Add functionality to various stages of the flag evaluation life-cycle.                                                                                       |
| ✅      | [Logging](#logging)                                                 | Integrate with popular logging packages.                                                                                                                     |
| ✅      | [Domains](#domains)                                                 | Logically bind clients with providers.                                                                                                                       |
| ✅      | [Eventing](#eventing)                                               | React to state changes in the provider or flag management system.                                                                                            |
| ✅      | [Shutdown](#shutdown)                                               | Gracefully clean up a provider during application shutdown.                                                                                                  |
| ✅      | [Extending](#extending)                                             | Extend OpenFeature with custom providers.                                                                                                          |

<sub>Implemented: ✅ | In-progress: ⚠️ | Not implemented yet: ❌</sub>

### Providers

[Providers](https://openfeature.dev/docs/reference/concepts/provider) are an abstraction between a flag management system and the OpenFeature SDK.
Look [here](https://openfeature.dev/ecosystem?instant_search%5BrefinementList%5D%5Btype%5D%5B0%5D=Provider&instant_search%5BrefinementList%5D%5Btechnology%5D%5B0%5D=Elixir) for a complete list of available providers.
If the provider you're looking for hasn't been created yet, see the [develop a provider](#develop-a-provider) section to learn how to build it yourself.

Once you've added a provider as a dependency, it can be registered with OpenFeature like this:

```elixir
provider = %OpenFeature.Provider.InMemory{
  flags: %{
    "v2_enabled" => %{
      disabled: false,
      default_variant: "one",
      variants: %{
        "on" => true,
        "off" => false
      }
    }
  }
}
{:ok, provider} = OpenFeature.set_provider(provider)
```

In some situations, it may be beneficial to register multiple providers in the same application.
This is possible using [domains](#domain), which is covered in more detail below.

### Targeting

Sometimes, the value of a flag must consider some dynamic criteria about the application or user, such as the user's location, IP, email address, or the server's location.
In OpenFeature, we refer to this as [targeting](https://openfeature.dev/specification/glossary#targeting).
If the flag management system you're using supports targeting, you can provide the input data using the [evaluation context](https://openfeature.dev/docs/reference/concepts/evaluation-context).

```elixir
# set a value to the global context
OpenFeature.set_global_context(%{region: "us-east-1"})

# set a value to the client context
client = OpenFeature.get_client() |> OpenFeature.Client.set_context(%{region: "us-east-1"})

# set a value to the invocation context
flag_value = OpenFeature.Client.get_boolean_value(client, "some-flag", flag, context: %{region: "us-east-1"})
```

### Hooks

[Hooks](https://openfeature.dev/docs/reference/concepts/hooks) allow for custom logic to be added at well-defined points of the flag evaluation life-cycle.
Look [here](https://openfeature.dev/ecosystem/?instant_search%5BrefinementList%5D%5Btype%5D%5B0%5D=Hook&instant_search%5BrefinementList%5D%5Btechnology%5D%5B0%5D=Elixir) for a complete list of available hooks.

Once you've added a hook as a dependency, it can be registered at the client or flag invocation level.

```elixir
## add a hook on this client, to run on all evaluations made by this client
client = OpenFeature.Client.add_hooks(client, [%OpenFeature.Hook{}])

## add a hook for this evaluation only
flag_value = OpenFeature.Client.get_boolean_value(client, flag_key, false, hooks: [%OpenFeature.Hook{}]);
```

### Logging

The Elixir SDK uses the default Elixir Logger.

### Domains

Clients can be assigned to a domain. A domain is a logical identifier which can be used to associate clients with a particular provider.
If a domain has no associated provider, the default provider is used.

```elixir
provider = %OpenFeature.Provider.InMemory{
  flags: %{
    "v2_enabled" => %{
      disabled: false,
      default_variant: "default",
      variants: %{
        "default" => true
      }
    }
  }
}

# registering the default provider
{:ok, _provider} = OpenFeature.set_provider(provider)
# registering a provider to a domain
{:ok, _provider} = OpenFeature.set_provider("my-domain", provider)

# A client bound to the default provider
default_client = OpenFeature.get_client()
# A client bound to the CachedProvider provider
domain_client = OpenFeature.get_client("my-domain")
```

### Eventing

Events allow you to react to state changes in the provider or underlying flag management system, such as flag definition changes, provider readiness, or error conditions.
Initialization events (`PROVIDER_READY` on success, `PROVIDER_ERROR` on failure) are dispatched for every provider.
Some providers support additional events, such as `PROVIDER_CONFIGURATION_CHANGED`.

Please refer to the documentation of the provider you're using to see what events are supported.

```elixir
# add an event handler to a client
OpenFeature.Client.add_event_handler(client, :configuration_changed, fn event_details ->
  # do something when the provider's flag settings change
end)
```

### Shutdown

The OpenFeature API provides a close function to perform a cleanup of all registered providers.
This should only be called when your application is in the process of shutting down.

```elixir
OpenFeature.shutdown()
```

## Extending

### Develop a provider

To develop a provider, you need to create a new project and include the OpenFeature SDK as a dependency.
This can be a new repository or included in [the existing contrib repository](https://github.com/open-feature/elixir-sdk-contrib) available under the OpenFeature organization.
You’ll then need to write the provider by implementing the `OpenFeature.Provider` behaviour exported by the OpenFeature SDK.

```elixir
defmodule OpenFeature.Provider.NoOp do
  alias OpenFeature.ResolutionDetails

  @behaviour OpenFeature.Provider

  defstruct name: "NoOp", domain: nil, state: :not_ready, hooks: []

  def initialize(provider, domain, _evaluation_context), do: {:ok, %{provider | state: :ready, domain: domain}}
  def shutdown(_provider), do: :ok

  def resolve_boolean_value(_provider, _key, default, _context), do: {:ok, %ResolutionDetails{value: default}}
  def resolve_string_value(_provider, _key, default, _context), do: {:ok, %ResolutionDetails{value: default}}
  def resolve_number_value(_provider, _key, default, _context), do: {:ok, %ResolutionDetails{value: default}}
  def resolve_map_value(_provider, _key, default, _context), do: {:ok, %ResolutionDetails{value: default}}
end

```

> Built a new provider? [Let us know](https://github.com/open-feature/openfeature.dev/issues/new?assignees=&labels=provider&projects=&template=document-provider.yaml&title=%5BProvider%5D%3A+) so we can add it to the docs!

<!-- x-hide-in-docs-start -->
## ⭐️ Support the project

- Give this repo a ⭐️!
- Follow us on social media:
  - Twitter: [@openfeature](https://twitter.com/openfeature)
  - LinkedIn: [OpenFeature](https://www.linkedin.com/company/openfeature/)
- Join us on [Slack](https://cloud-native.slack.com/archives/C0344AANLA1)
- For more, check out our [community page](https://openfeature.dev/community/)

## 🤝 Contributing

Interested in contributing? Great, we'd love your help! To get started, take a look at the [CONTRIBUTING](CONTRIBUTING.md) guide.

### Thanks to everyone who has already contributed

<a href="https://github.com/open-feature/elixir-sdk/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=open-feature/elixir-sdk" alt="Pictures of the folks who have contributed to the project" />
</a>


Made with [contrib.rocks](https://contrib.rocks).
<!-- x-hide-in-docs-end -->
