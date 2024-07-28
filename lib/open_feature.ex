defmodule OpenFeature do
  @moduledoc """
  Module for OpenFeature Flag Evaluation API
  """

  alias OpenFeature.Client
  alias OpenFeature.Provider
  alias OpenFeature.Store
  alias OpenFeature.Types

  @spec set_provider(domain :: Types.domain(), provider :: Provider.t()) :: {:ok, Provider.t()} | {:error, atom}
  def set_provider(domain \\ "default", provider) do
    with {:ok, provider} <- Provider.validate_provider(provider),
         {:not_set, old_provider} <- check_if_already_set(domain, provider),
         context = get_global_context(),
         {:ok, provider} <- Provider.initialize(domain, provider, context) do
      Store.set_provider(domain, provider)
      maybe_shutdown_old_provider(old_provider)
      {:ok, provider}
    end
  end

  @spec clear_providers() :: :ok
  def clear_providers, do: Store.clear_providers()

  @spec set_global_context(context :: Types.context()) :: :ok
  def set_global_context(context) when is_map(context), do: Store.set_context(context)

  @spec get_global_context() :: Types.context()
  def get_global_context, do: Store.get_context()

  @spec get_metadata(domain :: Types.domain()) :: Provider.t()
  def get_metadata(domain \\ "default") when is_binary(domain), do: Store.get_provider(domain)

  @spec get_client(domain :: Types.domain()) :: Client.t()
  def get_client(domain \\ "default") when is_binary(domain) do
    provider = Store.get_provider(domain)
    %Client{domain: domain, provider: provider}
  end

  @spec shutdown() :: :ok
  def shutdown, do: Enum.each(Store.list_providers(), &Provider.shutdown/1)

  defp check_if_already_set(domain, provider) do
    domain_provider = Store.get_provider(domain)

    if Provider.equal?(domain_provider, provider) do
      {:ok, domain_provider}
    else
      {:not_set, domain_provider}
    end
  end

  defp maybe_shutdown_old_provider(old_provider) do
    Store.list_providers()
    |> Enum.any?(fn provider ->
      Provider.equal?(provider, old_provider)
    end)
    |> if do
      Provider.shutdown(old_provider)
    end
  end
end
