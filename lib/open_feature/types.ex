defmodule OpenFeature.Types do
  @moduledoc """
  OpenFeature types.
  """
  @moduledoc since: "0.1.0"

  @type domain :: binary
  @type flag_value :: boolean | binary | number | map
  @type flag_type :: :boolean | :string | :number | :map
  @type context :: %{optional(binary) => any()}
  @type error_code ::
          :provider_not_ready
          | :flag_not_found
          | :parse_error
          | :type_mismatch
          | :targeting_key_missing
          | :invalid_context
          | :provider_fatal
          | :general
  @type reason :: :static | :default | :targeting_match | :split | :cached | :disabled | :unknown | :stale | :error
  @type flag_metadata :: %{binary => boolean | binary | number}
  @type provider_status :: :not_ready | :ready | :stale
  @type event_type :: :ready | :error | :configuration_changed | :stale
  @type event_details :: %{:provider => binary, optional(:domain) => binary, optional(binary | atom) => any}
  @type event_handler :: (event_details -> any())
end
