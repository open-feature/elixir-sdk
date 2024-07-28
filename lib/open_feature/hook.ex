defmodule OpenFeature.Hook do
  @moduledoc """
  OpenFeature Hook struct
  """
  @moduledoc since: "0.1.0"

  alias OpenFeature.EvaluationDetails
  alias OpenFeature.HookContext
  alias OpenFeature.Types

  defstruct [:before, :after, :error, :finally]

  @type hook_hints :: %{optional(binary) => any}
  @type before :: (HookContext.t(), hook_hints -> Types.context()) | nil
  @type after_hook :: (HookContext.t(), EvaluationDetails.t(), hook_hints -> any) | nil
  @type error :: (HookContext.t(), any, hook_hints -> any) | nil
  @type finally :: (HookContext.t(), hook_hints -> any) | nil

  @type t :: %__MODULE__{
          before: before,
          after: after_hook,
          error: error,
          finally: finally
        }
end
