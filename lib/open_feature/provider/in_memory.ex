defmodule OpenFeature.Provider.InMemory do
  @moduledoc """
  In-memory provider for OpenFeature.
  """

  alias OpenFeature.Provider
  alias OpenFeature.ResolutionDetails

  @behaviour Provider

  defstruct name: "InMemory", domain: nil, state: :ready, hooks: [], flags: %{}

  def initialize(provider, domain, _evaluation_context), do: {:ok, %{provider | state: :ready, domain: domain}}
  def shutdown(_provider), do: :ok

  def resolve_boolean_value(provider, key, default, context), do: resolve_value(provider, key, default, context)
  def resolve_string_value(provider, key, default, context), do: resolve_value(provider, key, default, context)
  def resolve_number_value(provider, key, default, context), do: resolve_value(provider, key, default, context)
  def resolve_map_value(provider, key, default, context), do: resolve_value(provider, key, default, context)

  defp resolve_value(%__MODULE__{flags: flags}, key, default, context) do
    with {:ok, flag} <- get_flag(flags, key),
         :ok <- check_flag_enabled(flag, default),
         {:ok, variant, context?} <- get_variant(flag, context),
         {:ok, value} <- get_value(flag, variant) do
      {:ok, struct(ResolutionDetails, %{value: value, variant: variant, reason: get_reason(context?)})}
    end
  rescue
    e -> {:error, :unexpected_error, e}
  end

  defp get_flag(flags, key) do
    with :error <- Map.fetch(flags, key) do
      {:error, :flag_not_found}
    end
  end

  defp check_flag_enabled(%{disabled: false}, _default), do: :ok
  defp check_flag_enabled(%{disabled: true}, default), do: {:ok, %{value: default, reason: :disabled}}

  defp get_variant(%{context_evaluator: context_evaluator}, context) when is_function(context_evaluator, 1),
    do: {:ok, context_evaluator.(context), true}

  defp get_variant(%{default_variant: default_variant}, _context), do: {:ok, default_variant, false}

  defp get_value(_, nil), do: {:error, :variant_not_found, nil}

  defp get_value(%{variants: variants}, variant) do
    with :error <- Map.fetch(variants, variant) do
      {:error, :variant_not_found, variant}
    end
  end

  defp get_reason(true), do: :targeting_match
  defp get_reason(false), do: :static
end
