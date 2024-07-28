defmodule OpenFeature.ResolutionDetails do
  @moduledoc """
  OpenFeature ResolutionDetails struct.
  """
  @moduledoc since: "0.1.0"

  alias OpenFeature.Types

  @enforce_keys [:value]
  defstruct [:value, :error_code, :error_message, :reason, :variant, :flag_metadata]

  @type t :: %__MODULE__{
          value: Types.flag_value(),
          error_code: Types.error_code() | nil,
          error_message: binary | nil,
          reason: Types.reason() | nil,
          variant: binary | nil,
          flag_metadata: Types.flag_metadata() | nil
        }
end
