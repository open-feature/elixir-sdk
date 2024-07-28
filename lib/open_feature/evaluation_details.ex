defmodule OpenFeature.EvaluationDetails do
  @moduledoc """
  OpenFeature EvaluationDetails structure
  """

  alias OpenFeature.Types

  @enforce_keys [:key, :value]
  defstruct [:key, :value, :error_code, :error_message, :reason, :variant, flag_metadata: %{}]

  @type t :: %__MODULE__{
          key: binary,
          value: Types.flag_value(),
          error_code: Types.error_code() | nil,
          error_message: binary | nil,
          reason: Types.reason() | nil,
          variant: binary | nil,
          flag_metadata: Types.flag_metadata() | nil
        }
end
