defmodule OpenFeature.Store do
  @moduledoc """
  OpenFeature.Store
  """

  use GenServer
  alias OpenFeature.Provider
  alias OpenFeature.Provider.NoOp
  alias OpenFeature.Types

  @providers_table :open_feature_store_providers
  @context_table :open_feature_store_context

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec set_provider(domain :: Types.domain(), provider :: Provider.t()) :: :ok
  def set_provider(domain, provider) do
    :ets.insert(@providers_table, {domain, provider})
    :ok
  end

  @spec get_provider(domain :: Types.domain()) :: Provider.t()
  def get_provider(domain) do
    case :ets.lookup(@providers_table, domain) do
      [{^domain, provider}] -> provider
      [] -> %NoOp{}
    end
  end

  @spec list_providers() :: [Provider.t()]
  def list_providers do
    @providers_table
    |> :ets.tab2list()
    |> Enum.map(fn {_, provider} -> provider end)
    |> Enum.uniq()
  end

  @spec clear_providers() :: :ok
  def clear_providers do
    :ets.delete_all_objects(@providers_table)
    :ets.insert(@providers_table, {"default", %NoOp{}})
    :ok
  end

  @spec set_context(context :: Types.context()) :: :ok
  def set_context(context) do
    :ets.insert(@context_table, {:context, context})
    :ok
  end

  @spec get_context() :: Types.context()
  def get_context do
    case :ets.lookup(@context_table, :context) do
      [{:context, context}] -> context
      [] -> %{}
    end
  end

  @impl true
  def init(:ok) do
    :ets.new(@providers_table, [:named_table, :set, :public])
    :ets.new(@context_table, [:named_table, :set, :public])
    :ets.insert(@providers_table, {"default", %NoOp{state: :ready}})
    :ets.insert(@context_table, {:context, %{}})
    {:ok, nil, :hibernate}
  end
end
