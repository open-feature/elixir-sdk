defmodule OpenFeature do
  @moduledoc """
  Module for OpenFeature Flag Evaluation API
  """
  @moduledoc since: "0.1.0"

  alias OpenFeature.Client
  alias OpenFeature.Provider
  alias OpenFeature.Store
  alias OpenFeature.Types

  @doc """
  Sets the provider for a given domain.

  The provider is validated and is initialized with the global context.
  If a provider is already set for the domain, it will be replaced and shutdown if not set for other domains.
  If the provider is the same as the one already set, it will not be replaced.
  If the provider is invalid or fails to be initialized, an error will be returned.
  If no domain is provided, the default domain will be used.
  """
  @doc since: "0.1.0"
  @spec set_provider(domain :: Types.domain(), provider :: Provider.t()) :: {:ok, Provider.t()} | {:error, atom}
  def set_provider(domain \\ "default", provider) do
    with {:ok, provider} <- Provider.validate_provider(provider),
         {:replace, old_provider} <- check_if_already_set(domain, provider),
         context = get_global_context(),
         {:ok, provider} <- Provider.initialize(domain, provider, context) do
      Store.set_provider(domain, provider)
      maybe_shutdown_old_provider(old_provider)
      {:ok, provider}
    end
  end

  @doc """
  Clears all stored providers.
  """
  @doc since: "0.1.0"
  @spec clear_providers() :: :ok
  def clear_providers, do: Store.clear_providers()

  @doc """
  Sets the global context.
  """
  @doc since: "0.1.0"
  @spec set_global_context(context :: Types.context()) :: :ok
  def set_global_context(context) when is_map(context), do: Store.set_context(context)

  @doc """
  Gets the global context.
  """
  @doc since: "0.1.0"
  @spec get_global_context() :: Types.context()
  def get_global_context, do: Store.get_context()

  @doc """
  Gets the provider for a given domain. If no domain is provided, the default domain will be used.
  """
  @doc since: "0.1.0"
  @spec get_provider(domain :: Types.domain()) :: Provider.t()
  def get_provider(domain \\ "default") when is_binary(domain), do: Store.get_provider(domain)

  @doc """
  Creates a client for a given domain.

  If no domain is provided, the default domain will be used.
  If no provider is set for the domain, the default provider will be used.
  """
  @doc since: "0.1.0"
  @spec get_client(domain :: Types.domain()) :: Client.t()
  def get_client(domain \\ "default") when is_binary(domain) do
    provider = Store.get_provider(domain)
    %Client{domain: domain, provider: provider}
  end

  @doc """
  Shuts down all providers.
  """
  @doc since: "0.1.0"
  @spec shutdown() :: :ok
  def shutdown, do: Enum.each(Store.list_providers(), &Provider.shutdown/1)

  defp check_if_already_set(domain, provider) do
    domain_provider = Store.get_provider(domain)

    if Provider.equal?(domain_provider, provider) do
      {:ok, domain_provider}
    else
      {:replace, domain_provider}
    end
  end

  defp maybe_shutdown_old_provider(old_provider) do
    Store.list_providers()
    |> Enum.any?(&Provider.equal?(&1, old_provider))
    |> then(fn
      false -> Provider.shutdown(old_provider)
      true -> :ok
    end)
  end
end
