defmodule OpenFeature.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_feature,
      version: "0.1.3",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_paths: ["test/unit", "test/integration"],
      deps: deps(),
      preferred_cli_env: [
        test: :test,
        docs: :docs,
        "hex.publish": :docs
      ],

      # Docs
      name: "OpenFeature",
      source_url: "https://github.com/open-feature/elixir-sdk",
      homepage_url: "https://openfeature.dev",
      docs: docs(),

      # Hex
      description: "OpenFeature SDK for Elixir",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OpenFeature.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :docs, runtime: false},
      {:mimic, "~> 1.12", only: :test}
    ]
  end

  defp docs do
    [main: "OpenFeature", extras: ["README.md", "LICENSE", "CONTRIBUTING.md", "CHANGELOG.md"]]
  end

  defp package do
    [
      maintainers: ["Eduardo Cunha"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/open-feature/elixir-sdk",
        "Changelog" => "https://hexdocs.pm/open_feature/changelog.html"
      }
    ]
  end
end
