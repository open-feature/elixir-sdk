defmodule OpenFeature.Provider.InMemoryTest do
  use ExUnit.Case, async: true
  alias OpenFeature.Provider.InMemory
  alias OpenFeature.ResolutionDetails

  describe "initialize/3" do
    test "sets the state to :ready and assigns the domain" do
      provider = %InMemory{}
      domain = "test_domain"
      assert {:ok, %{state: :ready, domain: ^domain}} = InMemory.initialize(provider, domain, %{})
    end
  end

  describe "shutdown/1" do
    test "returns :ok" do
      provider = %InMemory{}
      assert :ok = InMemory.shutdown(provider)
    end
  end

  describe "resolve_boolean_value/4" do
    test "returns the expected result" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "variant",
            variants: %{"variant" => true}
          }
        }
      }

      key = "test_key"
      default = true
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: true, variant: "variant", reason: :static}}

      assert ^expected_result = InMemory.resolve_boolean_value(provider, key, default, context)
    end

    test "returns the expected result when context_evaluator returns an existing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"existing_variant" => true},
            context_evaluator: fn _context -> "existing_variant" end
          }
        }
      }

      key = "test_key"
      default = false
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: true, variant: "existing_variant", reason: :targeting_match}}

      assert ^expected_result = InMemory.resolve_boolean_value(provider, key, default, context)
    end

    test "returns error when context_evaluator returns a missing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"default_variant" => true},
            context_evaluator: fn _context -> "missing_variant" end
          }
        }
      }

      key = "test_key"
      default = false
      context = %{}

      assert {:error, :variant_not_found, "missing_variant"} =
               InMemory.resolve_boolean_value(provider, key, default, context)
    end

    test "returns default when key is missing" do
      provider = %InMemory{flags: %{}}
      key = "missing_key"
      default = true
      context = %{}

      assert {:error, :flag_not_found} = InMemory.resolve_boolean_value(provider, key, default, context)
    end

    test "returns default when key is disabled" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: true,
            default_variant: "variant",
            variants: %{"variant" => true}
          }
        }
      }

      key = "test_key"
      default = true
      context = %{}
      expected_result = {:ok, %{value: true, reason: :disabled}}

      assert ^expected_result = InMemory.resolve_boolean_value(provider, key, default, context)
    end
  end

  describe "resolve_string_value/4" do
    test "returns the expected result" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "variant",
            variants: %{"variant" => "value"}
          }
        }
      }

      key = "test_key"
      default = "default"
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: "value", variant: "variant", reason: :static}}

      assert ^expected_result = InMemory.resolve_string_value(provider, key, default, context)
    end

    test "returns the expected result when context_evaluator returns an existing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"existing_variant" => "variant"},
            context_evaluator: fn _context -> "existing_variant" end
          }
        }
      }

      key = "test_key"
      default = "default"
      context = %{}

      expected_result =
        {:ok, %ResolutionDetails{value: "variant", variant: "existing_variant", reason: :targeting_match}}

      assert ^expected_result = InMemory.resolve_string_value(provider, key, default, context)
    end

    test "returns error when context_evaluator returns a missing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"default_variant" => "variant"},
            context_evaluator: fn _context -> "missing_variant" end
          }
        }
      }

      key = "test_key"
      default = "default"
      context = %{}

      assert {:error, :variant_not_found, "missing_variant"} =
               InMemory.resolve_string_value(provider, key, default, context)
    end

    test "returns default when key is missing" do
      provider = %InMemory{flags: %{}}
      key = "missing_key"
      default = "default"
      context = %{}

      assert {:error, :flag_not_found} = InMemory.resolve_string_value(provider, key, default, context)
    end

    test "returns default when key is disabled" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: true,
            default_variant: "variant",
            variants: %{"variant" => "value"}
          }
        }
      }

      key = "test_key"
      default = "default"
      context = %{}
      expected_result = {:ok, %{value: "default", reason: :disabled}}

      assert ^expected_result = InMemory.resolve_string_value(provider, key, default, context)
    end
  end

  describe "resolve_number_value/4" do
    test "returns the expected result" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "variant",
            variants: %{"variant" => 42}
          }
        }
      }

      key = "test_key"
      default = 42
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: 42, variant: "variant", reason: :static}}

      assert ^expected_result = InMemory.resolve_number_value(provider, key, default, context)
    end

    test "returns the expected result when context_evaluator returns an existing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"existing_variant" => 123},
            context_evaluator: fn _context -> "existing_variant" end
          }
        }
      }

      key = "test_key"
      default = 42
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: 123, variant: "existing_variant", reason: :targeting_match}}

      assert ^expected_result = InMemory.resolve_number_value(provider, key, default, context)
    end

    test "returns error when context_evaluator returns a missing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"default_variant" => 123},
            context_evaluator: fn _context -> "missing_variant" end
          }
        }
      }

      key = "test_key"
      default = 42
      context = %{}

      assert {:error, :variant_not_found, "missing_variant"} =
               InMemory.resolve_number_value(provider, key, default, context)
    end

    test "returns default when key is missing" do
      provider = %InMemory{flags: %{}}
      key = "missing_key"
      default = 42
      context = %{}

      assert {:error, :flag_not_found} = InMemory.resolve_number_value(provider, key, default, context)
    end

    test "returns default when key is disabled" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: true,
            default_variant: "variant",
            variants: %{"variant" => 42}
          }
        }
      }

      key = "test_key"
      default = 42
      context = %{}
      expected_result = {:ok, %{value: 42, reason: :disabled}}

      assert ^expected_result = InMemory.resolve_number_value(provider, key, default, context)
    end
  end

  describe "resolve_map_value/4" do
    test "returns the expected result" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "variant",
            variants: %{"variant" => %{}}
          }
        }
      }

      key = "test_key"
      default = %{}
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: %{}, variant: "variant", reason: :static}}

      assert ^expected_result = InMemory.resolve_map_value(provider, key, default, context)
    end

    test "returns the expected result when context_evaluator returns an existing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"existing_variant" => %{}},
            context_evaluator: fn _context -> "existing_variant" end
          }
        }
      }

      key = "test_key"
      default = %{}
      context = %{}
      expected_result = {:ok, %ResolutionDetails{value: %{}, variant: "existing_variant", reason: :targeting_match}}

      assert ^expected_result = InMemory.resolve_map_value(provider, key, default, context)
    end

    test "returns error when context_evaluator returns a missing variant" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: false,
            default_variant: "default_variant",
            variants: %{"default_variant" => %{}},
            context_evaluator: fn _context -> "missing_variant" end
          }
        }
      }

      key = "test_key"
      default = %{}
      context = %{}

      assert {:error, :variant_not_found, "missing_variant"} =
               InMemory.resolve_map_value(provider, key, default, context)
    end

    test "returns error when key is missing" do
      provider = %InMemory{flags: %{}}
      key = "missing_key"
      default = %{}
      context = %{}

      assert {:error, :flag_not_found} = InMemory.resolve_map_value(provider, key, default, context)
    end

    test "returns default when key is disabled" do
      provider = %InMemory{
        flags: %{
          "test_key" => %{
            disabled: true,
            default_variant: "variant",
            variants: %{"variant" => %{}}
          }
        }
      }

      key = "test_key"
      default = %{}
      context = %{}
      expected_result = {:ok, %{value: %{}, reason: :disabled}}

      assert ^expected_result = InMemory.resolve_map_value(provider, key, default, context)
    end
  end
end
