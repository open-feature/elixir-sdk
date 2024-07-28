defmodule Integration.ValueResolutionTest do
  use ExUnit.Case, async: false
  alias OpenFeature.Client
  alias OpenFeature.EvaluationDetails
  alias OpenFeature.Provider.InMemory

  setup_all do
    OpenFeature.clear_providers()

    provider = %InMemory{
      flags: %{
        "flag_key" => %{
          disabled: false,
          default_variant: "default",
          variants: %{
            "default" => "default_value"
          }
        },
        "target_key" => %{
          disabled: false,
          default_variant: "default",
          context_evaluator: fn context -> Map.get(context, :variant, "default") end,
          variants: %{
            "default" => "default_value",
            "variant1" => "variant1_value"
          }
        },
        "disabled_flag" => %{
          disabled: true,
          default_variant: "default",
          variants: %{
            "default" => "default_value"
          }
        }
      }
    }

    OpenFeature.set_provider("domain", provider)
    client = OpenFeature.get_client("domain")

    {:ok, client: client}
  end

  describe "Value resolution" do
    test "resolves a static value", %{client: client} do
      assert %EvaluationDetails{value: "default_value", variant: "default", reason: :static} =
               Client.get_string_details(client, "flag_key", "default")
    end

    test "resolves a targetted value", %{client: client} do
      assert %EvaluationDetails{value: "variant1_value", variant: "variant1", reason: :targeting_match} =
               Client.get_string_details(client, "target_key", "default", context: %{variant: "variant1"})
    end

    test "resolves a flag without variant", %{client: client} do
      assert %EvaluationDetails{
               value: "default",
               variant: nil,
               reason: :error,
               error_code: :general,
               error_message: "variant not found"
             } =
               Client.get_string_details(client, "target_key", "default", context: %{variant: "variant2"})
    end

    test "resolves a disabled flag", %{client: client} do
      assert %EvaluationDetails{
               value: "default",
               variant: nil,
               reason: :disabled
             } =
               Client.get_string_details(client, "disabled_flag", "default")
    end

    test "resolves a non existant flag", %{client: client} do
      assert %EvaluationDetails{
               value: "default",
               variant: nil,
               reason: :error
             } =
               Client.get_string_details(client, "inexistent_flag", "default")
    end
  end
end
