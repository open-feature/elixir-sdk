defmodule OpenFeature.HookContext do
  @moduledoc """
  OpenFeature HookContext structure
  """

  alias OpenFeature.Client
  alias OpenFeature.Provider
  alias OpenFeature.Types

  @enforce_keys [:key, :default, :type, :context, :client, :provider]
  defstruct [:key, :default, :type, :context, :client, :provider]

  @type t :: %__MODULE__{
          key: binary,
          default: Types.flag_value(),
          type: Types.flag_type(),
          context: Types.context(),
          client: Client.t(),
          provider: Provider.t()
        }
end
