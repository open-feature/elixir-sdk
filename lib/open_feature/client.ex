defmodule OpenFeature.Client do
  @moduledoc """
  This module defines the `Client` struct and functions for managing the client's context and callbacks.
  """
  @moduledoc since: "0.1.0"

  require Logger
  alias OpenFeature.EvaluationDetails
  alias OpenFeature.EventEmitter
  alias OpenFeature.Hook
  alias OpenFeature.HookContext
  alias OpenFeature.Provider
  alias OpenFeature.Types

  @enforce_keys [:domain, :provider]
  defstruct [:domain, :provider, context: %{}, hooks: []]

  @type t :: %__MODULE__{
          domain: Types.domain(),
          provider: Provider.t(),
          context: Types.context(),
          hooks: [Hook.t()]
        }
  @type options :: keyword()

  @doc """
  Sets the context for the client.
  """
  @doc since: "0.1.0"
  @spec set_context(client :: t(), context :: Types.context()) :: t()
  def set_context(client, context) do
    Map.put(client, :context, context)
  end

  @doc """
  Retrieves the context of the client.
  """
  @doc since: "0.1.0"
  @spec get_context(client :: t()) :: Types.context()
  def get_context(client) do
    Map.fetch!(client, :context)
  end

  @doc """
  Adds hooks to the end of the list of current client hooks.
  """
  @doc since: "0.1.0"
  @spec add_hooks(client :: t(), hooks :: [Hook.t()]) :: t()
  def add_hooks(client, hooks) do
    Map.update!(client, :hooks, &Enum.concat(&1, hooks))
  end

  @doc """
  Retrieves the list of hooks for the client.
  """
  @doc since: "0.1.0"
  @spec get_hooks(client :: t()) :: [Hook.t()]
  def get_hooks(client) do
    Map.fetch!(client, :hooks)
  end

  @doc """
  Clears all hooks for the client.
  """
  @doc since: "0.1.0"
  @spec clear_hooks(client :: t()) :: t()
  def clear_hooks(client) do
    %{client | hooks: []}
  end

  @doc """
  Adds an event handler for the client.

  If the event type is the same as the client's provider state, the handler will be executed immediately.
  """
  @doc since: "0.1.0"
  @spec add_event_handler(client :: t(), type :: Types.event_type(), handler :: Types.event_handler()) :: :ok
  def add_event_handler(client, type, handler) do
    EventEmitter.add_handler(client.domain, type, handler)

    if type == client.provider.state do
      try do
        handler.(%{provider: client.provider.name, domain: client.domain})
      rescue
        e -> Logger.error("Error running event handler. Error: #{inspect(e)}")
      end
    end

    :ok
  end

  @doc """
  Removes an event handler for the client.
  """
  @doc since: "0.1.0"
  @spec remove_event_handler(client :: t(), type :: Types.event_type(), handler :: Types.event_handler()) :: :ok
  def remove_event_handler(client, type, handler) do
    EventEmitter.remove_handler(client.domain, type, handler)
  end

  @doc """
  Lists all event handlers for the client.
  """
  @doc since: "0.1.0"
  @spec list_handlers(client :: t(), type :: Types.event_type()) :: [Types.event_handler()]
  def list_handlers(client, type) do
    EventEmitter.list_handlers(client.domain, type)
  end

  @doc """
  Clears all event handlers for the client.
  """
  @doc since: "0.1.0"
  @spec clear_handlers(client :: t()) :: :ok
  def clear_handlers(client) do
    EventEmitter.clear_handlers(client.domain)
  end

  @doc """
  Returns a boolean value for a given client flag.
  """
  @doc since: "0.1.0"
  @spec get_boolean_value(
          client :: t,
          key :: binary,
          default :: boolean,
          opts :: options
        ) :: boolean
  def get_boolean_value(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_boolean(default) do
    evaluate_value(client, :boolean, key, default, opts)
  end

  @doc """
  Returns a string value for a given client flag.
  """
  @doc since: "0.1.0"
  @spec get_string_value(
          client :: t,
          key :: binary,
          default :: binary,
          opts :: options
        ) :: binary
  def get_string_value(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_binary(default) do
    evaluate_value(client, :string, key, default, opts)
  end

  @doc """
  Returns a number value for a given client flag.
  """
  @doc since: "0.1.0"
  @spec get_number_value(
          client :: t,
          key :: binary,
          default :: number,
          opts :: options
        ) :: number
  def get_number_value(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_number(default) do
    evaluate_value(client, :number, key, default, opts)
  end

  @doc """
  Returns a map value for a given client flag.
  """
  @doc since: "0.1.0"
  @spec get_map_value(
          client :: t,
          key :: binary,
          default :: map,
          opts :: options
        ) :: map
  def get_map_value(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_map(default) do
    evaluate_value(client, :map, key, default, opts)
  end

  @doc """
  Returns the evaluation details for a given client flag with boolean value.
  """
  @doc since: "0.1.0"
  @spec get_boolean_details(
          client :: t,
          key :: binary,
          default :: boolean,
          opts :: options
        ) :: EvaluationDetails.t()
  def get_boolean_details(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_boolean(default) do
    evaluate(client, :boolean, key, default, opts)
  end

  @doc """
  Returns the evaluation details for a given client flag with string value.
  """
  @doc since: "0.1.0"
  @spec get_string_details(
          client :: t,
          key :: binary,
          default :: binary,
          opts :: options
        ) :: EvaluationDetails.t()
  def get_string_details(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_binary(default) do
    evaluate(client, :string, key, default, opts)
  end

  @doc """
  Returns the evaluation details for a given client flag with number value.
  """
  @doc since: "0.1.0"
  @spec get_number_details(
          client :: t,
          key :: binary,
          default :: number,
          opts :: options
        ) :: EvaluationDetails.t()
  def get_number_details(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_number(default) do
    evaluate(client, :number, key, default, opts)
  end

  @doc """
  Returns the evaluation details for a given client flag with map value.
  """
  @doc since: "0.1.0"
  @spec get_map_details(
          client :: t,
          key :: binary,
          default :: map,
          opts :: options
        ) :: EvaluationDetails.t()
  def get_map_details(client, key, default, opts \\ [])
      when is_struct(client, __MODULE__) and is_map(default) do
    evaluate(client, :map, key, default, opts)
  end

  defp evaluate(client, type, key, default, opts) do
    client_hooks = get_hooks(client)
    evaluate_hooks = Keyword.get(opts, :hooks, [])
    all_hooks = Enum.concat([client_hooks, evaluate_hooks, client.provider.hooks])

    evaluate_context = Keyword.get(opts, :context, %{})

    merged_context =
      OpenFeature.get_global_context()
      |> Map.merge(client.context)
      |> Map.merge(evaluate_context)

    hook_context = %HookContext{
      key: key,
      default: default,
      type: type,
      context: merged_context,
      client: client,
      provider: client.provider
    }

    try do
      before_hooks(all_hooks, hook_context, opts)

      short_circuit_if_not_ready(client)

      evaluation_details = evaluation_details(client, type, key, default, merged_context)

      after_hooks(all_hooks, hook_context, evaluation_details, opts)

      evaluation_details
    rescue
      e ->
        error_hooks(all_hooks, hook_context, e, opts)
        handle_evaluate_error(e, key, default)
    after
      all_hooks
      |> Enum.reverse()
      |> finally_hooks(hook_context, opts)
    end
  end

  defp evaluate_value(client, type, key, default, opts) do
    client
    |> evaluate(type, key, default, opts)
    |> Map.fetch!(:value)
  end

  defp short_circuit_if_not_ready(%__MODULE__{provider: provider}) do
    case Map.get(provider, :state) do
      :not_ready -> raise "provider_not_ready"
      :fatal -> raise "provider_fatal"
      _state -> :ok
    end
  end

  defp evaluation_details(client, type, key, default, context) do
    details =
      client
      |> resolve_details(type, key, default, context)
      |> Map.from_struct()
      |> Map.put(:key, key)

    struct(EvaluationDetails, details)
  end

  defp resolve_details(client, type, key, default, context) do
    %__MODULE__{provider: provider} = client

    case Provider.resolve_value(provider, type, key, default, context) do
      {:ok, evaluation_details} ->
        evaluation_details

      {:error, :flag_not_found} ->
        %EvaluationDetails{
          key: key,
          value: default,
          reason: :error,
          error_code: :flag_not_found,
          error_message: "flag not found"
        }

      {:error, :variant_not_found, variant} ->
        %EvaluationDetails{
          key: key,
          value: default,
          reason: :error,
          error_code: :general,
          error_message: "variant not found, variant: #{inspect(variant)}"
        }

      {:error, :unexpected_error, error} ->
        %EvaluationDetails{
          key: key,
          value: default,
          reason: :error,
          error_code: :general,
          error_message: "unexpected error, error: #{inspect(error)}"
        }
    end
  end

  defp before_hooks(hooks, hook_context, opts) do
    hook_hints = Keyword.get(opts, :hook_hints, %{})

    Enum.each(hooks, fn
      %Hook{before: nil} -> :ok
      %Hook{before: before} -> before.(hook_context, hook_hints)
    end)
  end

  defp after_hooks(hooks, hook_context, evaluation_details, opts) do
    hook_hints = Keyword.get(opts, :hook_hints, %{})

    Enum.each(hooks, fn
      %Hook{after: nil} -> :ok
      %Hook{after: after_hook} -> after_hook.(hook_context, evaluation_details, hook_hints)
    end)
  end

  defp error_hooks(hooks, hook_context, error, opts) do
    hook_hints = Keyword.get(opts, :hook_hints, %{})

    Enum.each(hooks, fn
      %Hook{error: nil} ->
        :ok

      %Hook{error: error_hook} ->
        try do
          error_hook.(hook_context, error, hook_hints)
        rescue
          _e -> :ok
        end
    end)
  end

  defp finally_hooks(hooks, hook_context, opts) do
    hook_hints = Keyword.get(opts, :hook_hints, %{})

    Enum.each(hooks, fn
      %Hook{finally: nil} ->
        :ok

      %Hook{finally: finally} ->
        try do
          finally.(hook_context, hook_hints)
        rescue
          _e -> :ok
        end
    end)
  end

  defp handle_evaluate_error(%RuntimeError{message: "provider_not_ready"}, key, default) do
    %EvaluationDetails{
      key: key,
      value: default,
      reason: :error,
      error_code: :provider_not_ready,
      error_message: "provider not ready"
    }
  end

  defp handle_evaluate_error(%RuntimeError{message: "provider_fatal"}, key, default) do
    %EvaluationDetails{
      key: key,
      value: default,
      reason: :error,
      error_code: :provider_fatal,
      error_message: "provider fatal"
    }
  end

  defp handle_evaluate_error(e, key, default) do
    %EvaluationDetails{
      key: key,
      value: default,
      reason: :error,
      error_code: :general,
      error_message: Exception.message(e)
    }
  end
end
