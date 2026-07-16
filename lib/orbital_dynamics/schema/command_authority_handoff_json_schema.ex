defmodule OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema do
  @moduledoc false

  @string_fields [
    "command_authority_status",
    "planned_command_authority_status",
    "realized_command_authority_status",
    "command_authority_status_match_status",
    "required_authority",
    "planned_required_authority",
    "realized_required_authority",
    "required_authority_match_status",
    "command_safety_status",
    "planned_command_safety_status",
    "realized_command_safety_status",
    "command_safety_status_match_status",
    "command_authorized_match_status",
    "command_safety_checked_match_status"
  ]

  @boolean_fields [
    "command_authorized",
    "planned_command_authorized",
    "realized_command_authorized",
    "command_safety_checked",
    "planned_command_safety_checked",
    "realized_command_safety_checked"
  ]

  def properties do
    @string_fields
    |> typed_fields("string")
    |> Map.merge(typed_fields(@boolean_fields, "boolean"))
  end

  defp typed_fields(fields, type) do
    Map.new(fields, &{&1, %{"type" => type}})
  end
end
