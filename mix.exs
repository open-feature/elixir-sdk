defmodule OpenFeature.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_feature,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_paths: ["test/unit", "test/integration"],
      deps: deps(),

      # Docs
      name: "OpenFeature",
      source_url: "https://github.com/ejscunha/elixir-open-feature-sdk",
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:mimic, "~> 1.9", only: :test}
    ]
  end

  defp docs do
    [main: "OpenFeature", extras: ["README.md", "LICENSE"]]
  end

  defp package do
    [
      maintainers: ["Eduardo Cunha"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/ejscunha/elixir-open-feature-sdk"}
    ]
  end
end
