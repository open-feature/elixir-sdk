defmodule OpenFeature.Provider do
  @moduledoc """
  OpenFeature Provider behaviour
  """

  alias OpenFeature.EventEmitter
  alias OpenFeature.ResolutionDetails
  alias OpenFeature.Types

  @type t :: struct
  @type success :: {:ok, ResolutionDetails.t()}
  @type error ::
          {:error, :flag_not_found}
          | {:error, :variant_not_found, binary | nil}
          | {:error, :unexpected_error, Exception.t()}
  @type result :: success | error

  @callback initialize(provider :: t, domain :: binary, context :: Types.context()) ::
              {:ok, t} | {:error, Types.error_code()}
  @callback shutdown(provider :: t) :: :ok

  @callback resolve_boolean_value(provider :: t, key :: binary, default :: boolean, context :: Types.context()) ::
              result
  @callback resolve_string_value(provider :: t, key :: binary, default :: binary, context :: Types.context()) ::
              result
  @callback resolve_number_value(provider :: t, key :: binary, default :: number, context :: Types.context()) ::
              result
  @callback resolve_map_value(provider :: t, key :: binary, default :: map, context :: Types.context()) ::
              result

  @spec validate_provider(t()) :: {:ok, t} | {:error, :invalid_provider}
  def validate_provider(%module{} = provider) do
    if Code.ensure_loaded?(module) and
         function_exported?(module, :initialize, 3) and
         function_exported?(module, :shutdown, 1) and
         function_exported?(module, :resolve_boolean_value, 4) and
         function_exported?(module, :resolve_string_value, 4) and
         function_exported?(module, :resolve_number_value, 4) and
         function_exported?(module, :resolve_map_value, 4) do
      {:ok, provider}
    else
      {:error, :invalid_provider}
    end
  end

  def validate_provider(_provider), do: {:error, :invalid_provider}

  @spec initialize(domain :: binary, provider :: t, context :: Types.context()) :: {:ok, t} | {:error, any()}
  def initialize(domain, %module{} = provider, context) do
    {:ok, provider} = module.initialize(provider, domain, context)

    EventEmitter.emit(domain, :ready, %{domain: domain, provider: provider.name})
    {:ok, provider}
  rescue
    e ->
      EventEmitter.emit(domain, :error, %{domain: domain, provider: provider.name})
      {:error, e}
  end

  @spec resolve_value(t, Types.flag_type(), Types.flag_value(), Types.flag_value(), Types.context()) :: result
  def resolve_value(%module{} = provider, :boolean, key, default, context),
    do: module.resolve_boolean_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :string, key, default, context),
    do: module.resolve_string_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :number, key, default, context),
    do: module.resolve_number_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :map, key, default, context),
    do: module.resolve_map_value(provider, key, default, context)

  @spec shutdown(t) :: :ok
  def shutdown(%module{} = provider) do
    module.shutdown(provider)
  rescue
    _ -> :ok
  end

  @spec equal?(t, t) :: boolean
  def equal?(%module1{} = provider1, %module2{} = provider2) do
    module1 == module2 &&
      provider1.name == provider2.name &&
      provider1.domain == provider2.domain &&
      provider1.state == provider2.state
  end

  def equal?(_, _), do: false
end
