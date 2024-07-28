defmodule OpenFeature.StoreTest do
  use ExUnit.Case, async: false
  alias OpenFeature.Provider.NoOp
  alias OpenFeature.Store

  @providers_table :open_feature_store_providers
  @context_table :open_feature_store_context

  setup_all do
    :ets.delete_all_objects(@providers_table)
    :ets.delete_all_objects(@context_table)
    :ok
  end

  setup do
    on_exit(fn ->
      :ets.delete_all_objects(@providers_table)
      :ets.delete_all_objects(@context_table)
    end)
  end

  test "set_provider/2 sets the provider in the ETS table" do
    domain = "test_domain"
    provider = %NoOp{}
    assert :ok = Store.set_provider(domain, provider)
    assert [{^domain, ^provider}] = :ets.lookup(@providers_table, domain)
  end

  test "get_provider/1 retrieves the provider from the ETS table" do
    domain = "test_domain"
    provider = %NoOp{}
    Store.set_provider(domain, provider)
    assert provider == Store.get_provider(domain)
  end

  test "get_provider/1 returns NoOp if provider not found" do
    assert %NoOp{} = Store.get_provider("non_existent_domain")
  end

  test "list_providers/0 lists all unique providers" do
    provider1 = %NoOp{state: :active}
    provider2 = %NoOp{state: :ready}
    Store.set_provider("domain1", provider1)
    Store.set_provider("domain2", provider2)
    assert [provider1, provider2] == Store.list_providers()
  end

  test "clear_providers/0 clears all providers and sets default NoOp" do
    Store.set_provider("domain1", %NoOp{state: :ready})
    assert :ok = Store.clear_providers()
    assert [{"default", %NoOp{}}] = :ets.tab2list(@providers_table)
  end

  test "set_context/1 sets the context in the ETS table" do
    context = %{user: "test_user"}
    assert :ok = Store.set_context(context)
    assert [{:context, ^context}] = :ets.lookup(@context_table, :context)
  end

  test "get_context/0 retrieves the context from the ETS table" do
    context = %{user: "test_user"}
    Store.set_context(context)
    assert context == Store.get_context()
  end

  test "get_context/0 returns empty map if context not found" do
    assert %{} = Store.get_context()
  end
end
