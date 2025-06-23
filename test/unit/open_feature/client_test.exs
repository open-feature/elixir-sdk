defmodule OpenFeature.ClientTest do
  use ExUnit.Case, async: true
  use Mimic
  alias OpenFeature.Client
  alias OpenFeature.EvaluationDetails
  alias OpenFeature.EventEmitter
  alias OpenFeature.Hook
  alias OpenFeature.Provider
  alias OpenFeature.ResolutionDetails

  setup_all do
    stub(OpenFeature, :get_global_context, fn -> %{} end)

    stub(Provider, :resolve_value, fn _provider, _type, _key, default, _context ->
      {:ok, %ResolutionDetails{value: default}}
    end)

    :ok
  end

  setup do
    provider = %OpenFeature.Provider.NoOp{name: "test_provider", state: :ready, hooks: []}
    client = %Client{domain: "test_domain", provider: provider}
    {:ok, client: client}
  end

  describe "Public API" do
    test "set_context/2 sets the context", %{client: client} do
      context = %{user: "test_user"}
      updated_client = Client.set_context(client, context)
      assert updated_client.context == context
    end

    test "get_context/1 retrieves the context", %{client: client} do
      context = %{user: "test_user"}
      client = Client.set_context(client, context)
      assert Client.get_context(client) == context
    end

    test "add_hooks/2 adds hooks", %{client: client} do
      hooks1 = [%Hook{}, %Hook{}]
      hooks2 = [%Hook{}]
      updated_client = Client.add_hooks(client, hooks1)
      assert updated_client.hooks == hooks1
      updated_client2 = Client.add_hooks(updated_client, hooks2)
      assert updated_client2.hooks == hooks1 ++ hooks2
    end

    test "get_hooks/1 retrieves hooks", %{client: client} do
      hooks = [%Hook{}]
      client = Client.add_hooks(client, hooks)
      assert Client.get_hooks(client) == hooks
    end

    test "clear_hooks/1 clears hooks", %{client: client} do
      hooks = [%Hook{}]
      client = Client.add_hooks(client, hooks)
      updated_client = Client.clear_hooks(client)
      assert updated_client.hooks == []
    end

    test "add_event_handler/3 adds event handler", %{client: client} do
      handler = fn _ -> :ok end
      expect(EventEmitter, :add_handler, fn "test_domain", :ready, ^handler -> :ok end)
      assert :ok == Client.add_event_handler(client, :ready, handler)
    end

    test "add_event_handler/3 runs event handler if client provider is in the event type state", %{client: client} do
      parent = self()
      handler = fn _ -> send(parent, :handler_called) end
      expect(EventEmitter, :add_handler, fn "test_domain", :ready, ^handler -> :ok end)
      assert :ok == Client.add_event_handler(client, :ready, handler)
      assert_receive :handler_called
    end

    test "remove_event_handler/3 removes event handler", %{client: client} do
      handler = fn _ -> :ok end
      expect(EventEmitter, :remove_handler, fn "test_domain", :ready, ^handler -> :ok end)
      assert :ok == Client.remove_event_handler(client, :ready, handler)
    end

    test "list_handlers/2 lists event handlers", %{client: client} do
      handler = fn _ -> :ok end
      expect(EventEmitter, :list_handlers, fn "test_domain", :ready -> [handler] end)
      assert [handler] == Client.list_handlers(client, :ready)
    end

    test "clear_handlers/1 clears event handlers", %{client: client} do
      expect(EventEmitter, :clear_handlers, fn "test_domain" -> :ok end)
      assert :ok == Client.clear_handlers(client)
    end

    test "get_boolean_value/4 evaluates boolean value", %{client: client} do
      assert true == Client.get_boolean_value(client, "key", true)
    end

    test "get_string_value/4 evaluates string value", %{client: client} do
      assert "default" == Client.get_string_value(client, "key", "default")
    end

    test "get_number_value/4 evaluates number value", %{client: client} do
      assert 42 == Client.get_number_value(client, "key", 42)
    end

    test "get_map_value/4 evaluates map value", %{client: client} do
      default_map = %{key: "value"}
      assert default_map == Client.get_map_value(client, "key", default_map)
    end

    test "get_boolean_details/4 evaluates boolean details", %{client: client} do
      details = Client.get_boolean_details(client, "key", true)
      assert %EvaluationDetails{} = details
    end

    test "get_string_details/4 evaluates string details", %{client: client} do
      details = Client.get_string_details(client, "key", "default")
      assert %EvaluationDetails{} = details
    end

    test "get_number_details/4 evaluates number details", %{client: client} do
      details = Client.get_number_details(client, "key", 42)
      assert %EvaluationDetails{} = details
    end

    test "get_map_details/4 evaluates map details", %{client: client} do
      default_map = %{key: "value"}
      details = Client.get_map_details(client, "key", default_map)
      assert %EvaluationDetails{} = details
    end
  end

  describe "Hooks logic" do
    test "global, client and invocation contexts are merged", %{client: client} do
      parent = self()
      context = %{key: "value"}
      client_context = %{client_key: "value"}
      global_context = %{global_key: "value"}
      hints = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        finally: fn context, ^hints -> send(parent, {:hook_called, context, hints}) end
      }

      client =
        client
        |> Client.set_context(client_context)
        |> Client.add_hooks([hook])

      expect(OpenFeature, :get_global_context, fn -> global_context end)

      Client.get_boolean_value(client, key, default, context: context, hook_hints: hints)

      assert_receive {:hook_called,
                      %OpenFeature.HookContext{
                        context: %{key: "value", client_key: "value", global_key: "value"}
                      }, ^hints}
    end

    test "always executes finally hook", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        finally: fn %OpenFeature.HookContext{context: ^context}, _hints -> send(parent, :hook_called) end
      }

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :hook_called

      expect(Provider, :resolve_value, 1, fn _provider, _type, _key, _default, _context ->
        raise "some error"
      end)

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :hook_called

      hook = %Hook{
        before: fn _context, _hints -> raise "some error" end
      }

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :hook_called

      hook = %Hook{
        after: fn _context, _hints -> raise "some error" end,
        finally: fn %OpenFeature.HookContext{context: ^context}, _hints -> send(parent, :hook_called) end
      }

      client =
        client
        |> Client.clear_hooks()
        |> Client.add_hooks([hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :hook_called
    end

    test "before hooks are executed before the value resolution", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        before: fn _context, _hints -> send(parent, :hook_called) end
      }

      expect(Provider, :resolve_value, 1, fn _provider, _type, _key, _default, _context ->
        assert_receive :hook_called
        send(parent, :provider_called)
        {:ok, %ResolutionDetails{value: true}}
      end)

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :provider_called
    end

    test "after hooks are executed after the value resolution", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        after: fn _context, _details, _hints ->
          assert_receive :provider_called
          send(parent, :hook_called)
        end
      }

      expect(Provider, :resolve_value, 1, fn _provider, _type, _key, _default, _context ->
        send(parent, :provider_called)
        {:ok, %ResolutionDetails{value: true}}
      end)

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :hook_called
    end

    test "does not resolve value if an error occurs in before hooks", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        before: fn _context, _hints ->
          send(parent, :before_hook_called)
          raise "some error"
        end,
        error: fn _context, _error, _hints ->
          send(parent, :error_hook_called)
        end
      }

      reject(Provider, :resolve_value, 5)

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :before_hook_called
      assert_receive :error_hook_called
    end

    test "executes error hooks if an error happens in after hooks", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook = %Hook{
        after: fn _context, _details, _hints ->
          send(parent, :after_hook_called)
          raise "some error"
        end,
        error: fn _context, _error, _hints ->
          send(parent, :error_hook_called)
        end
      }

      client = Client.add_hooks(client, [hook])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :after_hook_called
      assert_receive :error_hook_called
    end

    test "skips error hook if an error happens", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook1 = %Hook{
        before: fn _context, _hints ->
          raise "some error"
        end,
        error: fn _context, _error, _hints ->
          send(parent, :error_hook1_called)
          raise "some error"
        end
      }

      hook2 = %Hook{
        error: fn _context, _error, _hints ->
          send(parent, :error_hook2_called)
        end
      }

      client = Client.add_hooks(client, [hook1, hook2])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :error_hook1_called
      assert_receive :error_hook2_called
    end

    test "skips finally hook if an error happens", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook1 = %Hook{
        finally: fn _context, _hints ->
          send(parent, :finally_hook1_called)
          raise "some error"
        end
      }

      hook2 = %Hook{
        finally: fn _context, _hints ->
          send(parent, :finally_hook2_called)
        end
      }

      client = Client.add_hooks(client, [hook2, hook1])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :finally_hook1_called
      assert_receive :finally_hook2_called
    end

    test "executes finally hooks in reverse order", %{client: client} do
      parent = self()
      context = %{key: "value"}
      key = "key"
      default = true

      hook1 = %Hook{
        finally: fn _context, _hints ->
          assert_receive :finally_hook2_called
          send(parent, :finally_hook1_called)
        end
      }

      hook2 = %Hook{
        finally: fn _context, _hints ->
          send(parent, :finally_hook2_called)
        end
      }

      client = Client.add_hooks(client, [hook1, hook2])

      Client.get_boolean_value(client, key, default, context: context)

      assert_receive :finally_hook1_called
    end
  end

  describe "Value resolution" do
    test "returns evaluation details for a successful value resolution", %{client: client} do
      key = "key"
      default = true

      expect(Provider, :resolve_value, fn _provider, _type, _key, _default, _context ->
        {:ok, %ResolutionDetails{value: false, reason: :static, variant: "variant", flag_metadata: %{}}}
      end)

      assert %EvaluationDetails{
               key: ^key,
               value: false,
               error_code: nil,
               error_message: nil,
               reason: :static,
               variant: "variant",
               flag_metadata: %{}
             } = Client.get_boolean_details(client, key, default)
    end

    test "returns evaluation details with default value if flag was not found", %{client: client} do
      key = "key"
      default = true

      expect(Provider, :resolve_value, fn _provider, _type, _key, _default, _context ->
        {:error, :flag_not_found}
      end)

      assert %EvaluationDetails{
               key: ^key,
               value: ^default,
               reason: :error,
               error_code: :flag_not_found,
               error_message: "flag not found"
             } = Client.get_boolean_details(client, key, default)
    end

    test "returns evaluation details with default value if variant was not found", %{client: client} do
      key = "key"
      default = true

      expect(Provider, :resolve_value, fn _provider, _type, _key, _default, _context ->
        {:error, :variant_not_found, "variant"}
      end)

      assert %EvaluationDetails{
               key: ^key,
               value: ^default,
               reason: :error,
               error_code: :general,
               error_message: "variant not found, variant: \"variant\""
             } = Client.get_boolean_details(client, key, default)
    end

    test "returns evaluation details with default value if an unexpected error happens", %{client: client} do
      key = "key"
      default = true

      expect(Provider, :resolve_value, fn _provider, _type, _key, _default, _context ->
        {:error, :unexpected_error, :error}
      end)

      assert %EvaluationDetails{
               key: ^key,
               value: ^default,
               reason: :error,
               error_code: :general,
               error_message: "unexpected error, error: :error"
             } = Client.get_boolean_details(client, key, default)
    end

    test "returns evaluation details with default value if provider is not ready", %{client: client} do
      key = "key"
      default = true

      client = put_in(client.provider.state, :not_ready)

      reject(Provider, :resolve_value, 5)

      assert %EvaluationDetails{
               key: ^key,
               value: ^default,
               reason: :error,
               error_code: :provider_not_ready,
               error_message: "provider not ready"
             } = Client.get_boolean_details(client, key, default)
    end

    test "returns evaluation details with default value if provider is fatal", %{client: client} do
      key = "key"
      default = true

      client = put_in(client.provider.state, :fatal)

      reject(Provider, :resolve_value, 5)

      assert %EvaluationDetails{
               key: ^key,
               value: ^default,
               reason: :error,
               error_code: :provider_fatal,
               error_message: "provider fatal"
             } = Client.get_boolean_details(client, key, default)
    end
  end
end
