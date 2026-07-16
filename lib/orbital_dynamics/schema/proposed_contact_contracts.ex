defmodule OrbitalDynamics.Schema.ProposedContactContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_interval: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.ActivityContracts

  def model_limits,
    do: ["artifact_level_only", "no_provider_reservation", "no_schedule_mutation"]

  def validate(issues, path, contact) do
    issues
    |> require_fields(path, contact, [
      "id",
      "type",
      "scenario_id",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "direction",
      "estimated_throughput_mb",
      "source_window",
      "cadence_import"
    ])
    |> validate_stable_ids(path, contact, [
      "id",
      "scenario_id",
      "timeline_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_equal(path, contact, "type", "downlink")
    |> expect_number(path, contact, "starts_at_s")
    |> expect_number(path, contact, "ends_at_s")
    |> expect_number(path, contact, "estimated_throughput_mb")
    |> expect_optional_type(path, contact, "station_availability", :binary)
    |> expect_optional_type(path, contact, "schedule_conflict_status", :binary)
    |> expect_optional_type(path, contact, "timeline_identity", :map)
    |> expect_optional_type(path, contact, "model_limits", :list)
    |> validate_string_list_items(path, contact, "model_limits")
    |> validate_interval(path, contact)
    |> validate_identity(path, contact)
    |> validate_model_limits(path, contact)
    |> ActivityContracts.validate_contact_fields(path, contact)
  end

  defp validate_identity(issues, path, contact) do
    source_window_id =
      case Map.get(contact, "source_window") do
        %{} = source_window -> Map.get(source_window, "id")
        _source_window -> nil
      end

    issues
    |> expect_field_equals(
      path,
      contact,
      "source_window_id",
      source_window_id,
      "must match source_window.id"
    )
    |> validate_timeline_identity(path, contact)
  end

  defp validate_timeline_identity(
         issues,
         path,
         %{
           "timeline_identity" => %{} = identity
         } = contact
       ) do
    issues
    |> expect_field_equals(
      path,
      contact,
      "timeline_id",
      Map.get(identity, "timeline_id"),
      "must match timeline_identity.timeline_id"
    )
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "activity_id",
      Map.get(contact, "id"),
      "must match top-level contact id"
    )
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "source_window_id",
      Map.get(contact, "source_window_id"),
      "must match top-level source_window_id"
    )
  end

  defp validate_timeline_identity(issues, _path, _contact), do: issues

  defp validate_model_limits(issues, path, contact) do
    case Map.get(contact, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits() do
          issues
        else
          [error(path <> ".model_limits", "must match proposed contact model limits") | issues]
        end

      _limits ->
        issues
    end
  end
end
