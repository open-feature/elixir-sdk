defmodule OpenFeature.Provider do
  @moduledoc """
  This module provides the behaviour that must be implemented by all providers.
  Also includes helper functions to be used with providers.
  """
  @moduledoc since: "0.1.0"

  alias OpenFeature.EventEmitter
  alias OpenFeature.HookContext
  alias OpenFeature.ResolutionDetails
  alias OpenFeature.Types

  @type t :: struct
  @type success :: {:ok, ResolutionDetails.t()}
  @type error ::
          {:error, :flag_not_found}
          | {:error, :variant_not_found, binary | nil}
          | {:error, :unexpected_error, Exception.t()}
  @type result :: success | error

  @doc """
  Initializes the provider with the domain and context, and sets the provider's state to `:ready`.
  """
  @doc since: "0.1.0"
  @callback initialize(provider :: t, domain :: binary, context :: Types.context()) ::
              {:ok, t} | {:error, Types.error_code()}
  @doc """
  Shuts down the provider and cleans up any resources.
  """
  @doc since: "0.1.0"
  @callback shutdown(provider :: t) :: :ok

  @doc """
  Resolves the boolean value of a flag based on the key, default value, and context.
  """
  @doc since: "0.1.0"
  @callback resolve_boolean_value(provider :: t, key :: binary, default :: boolean, context :: Types.context()) ::
              result
  @doc """
  Resolves the string value of a flag based on the key, default value, and context.
  """
  @doc since: "0.1.0"
  @callback resolve_string_value(provider :: t, key :: binary, default :: binary, context :: Types.context()) ::
              result
  @doc """
  Resolves the number value of a flag based on the key, default value, and context.
  """
  @doc since: "0.1.0"
  @callback resolve_number_value(provider :: t, key :: binary, default :: number, context :: Types.context()) ::
              result
  @doc """
  Resolves the map value of a flag based on the key, default value, and context.
  """
  @doc since: "0.1.0"
  @callback resolve_map_value(provider :: t, key :: binary, default :: map, context :: Types.context()) ::
              result

  @doc """
  Validates if the provider implements the required functions.
  """
  @doc since: "0.1.0"
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

  @doc """
  Initializes the provider and emits the `:ready` event if successful.
  If an error occurs, emits the `:error` event.
  """
  @doc since: "0.1.0"
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

  @doc """
  Resolves the value of a flag based on the key, default value, and context.
  """
  @doc since: "0.1.0"
  @spec resolve_value(t, Types.flag_type(), Types.flag_value(), Types.flag_value(), HookContext.t()) :: result
  def resolve_value(%module{} = provider, :boolean, key, default, context),
    do: module.resolve_boolean_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :string, key, default, context),
    do: module.resolve_string_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :number, key, default, context),
    do: module.resolve_number_value(provider, key, default, context)

  def resolve_value(%module{} = provider, :map, key, default, context),
    do: module.resolve_map_value(provider, key, default, context)

  @doc """
  Shuts down the provider and catches any errors that may occur.
  """
  @doc since: "0.1.0"
  @spec shutdown(t) :: :ok
  def shutdown(%module{} = provider) do
    module.shutdown(provider)
  rescue
    _ -> :ok
  end

  @doc """
  Checks if two providers are equal based on their module and name.
  """
  @doc since: "0.1.0"
  @spec equal?(t, t) :: boolean
  def equal?(%module1{} = provider1, %module2{} = provider2) do
    module1 == module2 && provider1.name == provider2.name
  end

  def equal?(_, _), do: false
end
