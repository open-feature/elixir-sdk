defmodule OpenFeature.Provider.NoOpTest do
  use ExUnit.Case, async: true
  alias OpenFeature.Provider.NoOp
  alias OpenFeature.ResolutionDetails

  setup do
    {:ok, provider: %NoOp{}}
  end

  test "initialize/3 sets state to :ready and assigns domain", %{provider: provider} do
    domain = "test_domain"
    {:ok, updated_provider} = NoOp.initialize(provider, domain, %{})
    assert updated_provider.state == :ready
    assert updated_provider.domain == domain
  end

  test "shutdown/1 returns :ok", %{provider: provider} do
    assert NoOp.shutdown(provider) == :ok
  end

  test "resolve_boolean_value/4 returns default value", %{provider: provider} do
    default = true
    {:ok, %ResolutionDetails{value: value}} = NoOp.resolve_boolean_value(provider, "key", default, %{})
    assert value == default
  end

  test "resolve_string_value/4 returns default value", %{provider: provider} do
    default = "default"
    {:ok, %ResolutionDetails{value: value}} = NoOp.resolve_string_value(provider, "key", default, %{})
    assert value == default
  end

  test "resolve_number_value/4 returns default value", %{provider: provider} do
    default = 42
    {:ok, %ResolutionDetails{value: value}} = NoOp.resolve_number_value(provider, "key", default, %{})
    assert value == default
  end

  test "resolve_map_value/4 returns default value", %{provider: provider} do
    default = %{key: "value"}
    {:ok, %ResolutionDetails{value: value}} = NoOp.resolve_map_value(provider, "key", default, %{})
    assert value == default
  end
end
