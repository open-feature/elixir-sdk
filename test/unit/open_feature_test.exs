defmodule OpenFeatureTest do
  use ExUnit.Case, async: true
  use Mimic
  alias OpenFeature.Client
  alias OpenFeature.Provider
  alias OpenFeature.Provider.NoOp
  alias OpenFeature.Store

  describe "set_provider/2" do
    test "sets a provider successfully" do
      provider = %NoOp{}
      domain = "default"
      context = %{}

      Provider
      |> expect(:validate_provider, fn ^provider -> {:ok, provider} end)
      |> expect(:initialize, fn ^domain, ^provider, ^context -> {:ok, provider} end)
      |> expect(:shutdown, fn _old_provider -> :ok end)

      Store
      |> expect(:set_provider, fn ^domain, ^provider -> :ok end)
      |> expect(:get_provider, fn ^domain -> nil end)
      |> expect(:get_context, fn -> context end)
      |> expect(:list_providers, fn -> [] end)

      assert {:ok, ^provider} = OpenFeature.set_provider(domain, provider)
    end

    test "returns provider if provider is already set" do
      provider = %NoOp{}
      domain = "default"

      expect(Provider, :validate_provider, fn ^provider -> {:ok, provider} end)

      expect(Store, :get_provider, fn ^domain -> provider end)

      assert {:ok, ^provider} = OpenFeature.set_provider(domain, provider)
    end

    test "returns error if provider validation fails" do
      provider = %NoOp{}
      domain = "default"

      expect(Provider, :validate_provider, fn ^provider -> {:error, :invalid_provider} end)

      assert {:error, :invalid_provider} = OpenFeature.set_provider(domain, provider)
    end
  end

  describe "clear_providers/0" do
    test "removes all providers from store" do
      expect(Store, :clear_providers, fn -> :ok end)

      assert :ok = OpenFeature.clear_providers()
    end
  end

  describe "set_global_context/1" do
    test "saves a global context in store" do
      context = %{user: "test"}

      expect(Store, :set_context, fn ^context -> :ok end)

      assert :ok = OpenFeature.set_global_context(context)
    end
  end

  describe "get_global_context/0" do
    test "retrieves the global context from store" do
      context = %{user: "test"}

      expect(Store, :get_context, fn -> context end)

      assert ^context = OpenFeature.get_global_context()
    end
  end

  describe "get_provider/1" do
    test "retrieves provider for a domain from store" do
      provider = %NoOp{}
      domain = "default"

      expect(Store, :get_provider, fn ^domain -> provider end)

      assert ^provider = OpenFeature.get_provider(domain)
    end
  end

  describe "get_client/1" do
    test "creates a client for a domain with the stored provider" do
      provider = %NoOp{}
      domain = "default"

      expect(Store, :get_provider, fn ^domain -> provider end)

      assert %Client{domain: ^domain, provider: ^provider} = OpenFeature.get_client(domain)
    end
  end

  describe "shutdown/0" do
    test "shuts down all providers" do
      provider1 = %NoOp{}
      provider2 = %NoOp{}

      expect(Store, :list_providers, fn -> [provider1, provider2] end)

      Provider
      |> expect(:shutdown, fn ^provider1 -> :ok end)
      |> expect(:shutdown, fn ^provider2 -> :ok end)

      assert :ok = OpenFeature.shutdown()
    end
  end
end
