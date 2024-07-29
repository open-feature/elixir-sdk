[![Version](https://img.shields.io/hexpm/v/open_feature.svg)](https://hex.pm/packages/open_feature)
[![Docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/open_feature/)
[![License](https://img.shields.io/hexpm/l/req.svg)](https://github.com/ejscunha/elixir-open-feature-sdk/blob/main/LICENSE.md)
[![CI](https://github.com/ejscunha/elixir-open-feature-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/ejscunha/elixir-open-feature-sdk/actions/workflows/ci.yml)

<!-- markdownlint-disable MD033 -->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/white/openfeature-horizontal-white.svg">
    <img align="center" alt="OpenFeature Logo" src="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/black/openfeature-horizontal-black.svg" />
  </picture>
</p>

<h2 align="center">OpenFeature Elixir SDK</h2>

## 👋 Hey there! Thanks for checking out the OpenFeature Elixir SDK

### What is OpenFeature?

[OpenFeature][openfeature-website] is an open standard that provides a vendor-agnostic, community-driven API for feature flagging that works with your favorite feature flag management tool.

### Why standardize feature flags?

Standardizing feature flags unifies tools and vendors behind a common interface which avoids vendor lock-in at the code level. Additionally, it offers a framework for building extensions and integrations and allows providers to focus on their unique value proposition.

## 🔧 Components

This repository contains the Elixir SDK.
For details, including API documentation, see the respective [Hex docs](https://hexdocs.pm/open_feature/).

## 💻 Instalation

The package can be installed by adding `open_feature` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:open_feature, "~> 0.1"}]
end
```

## 📓 Usage

```elixir
provider = %OpenFeature.Provider.InMemory{
  flags: %{
    "flag_key" => %{
      disabled: false,
      default_variant: "default",
      variants: %{
        "default" => "default_value"
      }
    }
  }
}
OpenFeature.set_provider("domain", provider)
client = OpenFeature.get_client("domain")
OpenFeature.Client.get_string_value(client, "flag_key", "default")
```

## ⭐️ Support the project

- Give this repo a ⭐️!
- Contribute to this repo
- Follow us social media:
  - Twitter: [@openfeature](https://twitter.com/openfeature)
  - LinkedIn: [OpenFeature](https://www.linkedin.com/company/openfeature/)
- Join us on [Slack](https://cloud-native.slack.com/archives/C0344AANLA1)
- For more check out our [community page](https://openfeature.dev/community/)

## 📜 License

[Apache License 2.0](LICENSE)

[openfeature-website]: https://openfeature.dev
