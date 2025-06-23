defmodule OpenFeature.ProviderTest do
  use ExUnit.Case, async: true
  use Mimic
  alias OpenFeature.EventEmitter
  alias OpenFeature.Provider
  alias OpenFeature.Provider.InMemory
  alias OpenFeature.Provider.NoOp
  alias OpenFeature.ResolutionDetails

  @no_op_provider %NoOp{}
  @in_memory_provider %InMemory{}
  @invalid_provider Date.utc_today()

  describe "validate_provider/1" do
    test "returns {:ok, provider} if the provider is a valid provider module" do
      assert {:ok, @no_op_provider} = Provider.validate_provider(@no_op_provider)
      assert {:ok, @in_memory_provider} = Provider.validate_provider(@in_memory_provider)
    end

    test "returns {:error, :invalid_provider} if given provider is not a valid provider module" do
      assert {:error, :invalid_provider} = Provider.validate_provider(@invalid_provider)
      assert {:error, :invalid_provider} = Provider.validate_provider(:invalid)
    end
  end

  describe "initialize/3" do
    test "should call the provider initialize function and emit the ready event when the provider initializes" do
      domain = "domain"
      context = %{}
      provider_name = @no_op_provider.name

      expect(NoOp, :initialize, fn @no_op_provider, ^domain, ^context ->
        {:ok, @no_op_provider}
      end)

      expect(EventEmitter, :emit, fn ^domain, :ready, %{domain: ^domain, provider: ^provider_name} ->
        :ok
      end)

      assert {:ok, @no_op_provider} = Provider.initialize(domain, @no_op_provider, context)
    end

    test "should return {:error, exception} and emit the error event if any exception happens" do
      domain = "domain"
      context = %{}
      provider_name = @no_op_provider.name

      expect(NoOp, :initialize, fn @no_op_provider, ^domain, ^context ->
        raise "error"
      end)

      expect(EventEmitter, :emit, fn ^domain, :error, %{domain: ^domain, provider: ^provider_name} ->
        :ok
      end)

      assert {:error, %RuntimeError{message: "error"}} = Provider.initialize(domain, @no_op_provider, context)
    end
  end

  describe "resolve_value/5" do
    test "should call the respective provider resolve function depending on the type provided" do
      key = "key"
      default = true
      context = %{}

      NoOp
      |> expect(:resolve_boolean_value, fn @no_op_provider, ^key, ^default, ^context ->
        {:ok, %ResolutionDetails{value: true}}
      end)
      |> expect(:resolve_number_value, fn @no_op_provider, ^key, ^default, ^context ->
        {:ok, %ResolutionDetails{value: 1}}
      end)

      assert {:ok, %ResolutionDetails{value: true}} =
               Provider.resolve_value(@no_op_provider, :boolean, key, default, context)

      assert {:ok, %ResolutionDetails{value: 1}} =
               Provider.resolve_value(@no_op_provider, :number, key, default, context)
    end
  end

  describe "shutdown/1" do
    test "should call the provider shutdown function" do
      expect(NoOp, :shutdown, fn @no_op_provider -> :ok end)
      assert :ok = Provider.shutdown(@no_op_provider)
    end

    test "should return :ok if the provider shutdown function raises an exception" do
      expect(NoOp, :shutdown, fn @no_op_provider -> raise "error" end)
      assert :ok = Provider.shutdown(@no_op_provider)
    end
  end

  describe "equal?/2" do
    test "should return true if the provided providers are equal" do
      assert Provider.equal?(@no_op_provider, @no_op_provider)
      assert Provider.equal?(@in_memory_provider, @in_memory_provider)
    end

    test "should return false if the provided providers are not equal" do
      refute Provider.equal?(@no_op_provider, @in_memory_provider)

      different_no_op = Map.put(@no_op_provider, :name, "some_name")
      refute Provider.equal?(@no_op_provider, different_no_op)
    end
  end
end
