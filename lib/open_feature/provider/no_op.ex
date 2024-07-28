defmodule OpenFeature.Provider.NoOp do
  @moduledoc """
  OpenFeature no-op provider
  """

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
