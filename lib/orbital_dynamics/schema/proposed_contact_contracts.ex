defmodule OrbitalDynamics.Schema.ProposedContactContracts do
  @moduledoc false

  def validate(issues, path, contact, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, contact, [
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
    |> validate_stable_ids(callbacks, path, contact, [
      "id",
      "scenario_id",
      "timeline_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_equal(callbacks, path, contact, "type", "downlink")
    |> expect_number(callbacks, path, contact, "starts_at_s")
    |> expect_number(callbacks, path, contact, "ends_at_s")
    |> expect_number(callbacks, path, contact, "estimated_throughput_mb")
    |> expect_optional_type(callbacks, path, contact, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, contact, "schedule_conflict_status", :binary)
    |> expect_optional_type(callbacks, path, contact, "timeline_identity", :map)
    |> expect_optional_type(callbacks, path, contact, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, contact, "model_limits")
    |> validate_interval(callbacks, path, contact)
    |> validate_identity(callbacks, path, contact)
    |> validate_model_limits(callbacks, path, contact)
    |> validate_contact_fields(callbacks, path, contact)
  end

  defp validate_identity(issues, callbacks, path, contact) do
    source_window_id =
      case Map.get(contact, "source_window") do
        %{} = source_window -> Map.get(source_window, "id")
        _source_window -> nil
      end

    issues
    |> expect_field_equals(
      callbacks,
      path,
      contact,
      "source_window_id",
      source_window_id,
      "must match source_window.id"
    )
    |> validate_timeline_identity(callbacks, path, contact)
  end

  defp validate_timeline_identity(
         issues,
         callbacks,
         path,
         %{
           "timeline_identity" => %{} = identity
         } = contact
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      contact,
      "timeline_id",
      Map.get(identity, "timeline_id"),
      "must match timeline_identity.timeline_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "activity_id",
      Map.get(contact, "id"),
      "must match top-level contact id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "source_window_id",
      Map.get(contact, "source_window_id"),
      "must match top-level source_window_id"
    )
  end

  defp validate_timeline_identity(issues, _callbacks, _path, _contact), do: issues

  defp validate_model_limits(issues, callbacks, path, contact) do
    case Map.get(contact, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == proposed_contact_model_limits(callbacks) do
          issues
        else
          [
            error(callbacks, path <> ".model_limits", "must match proposed contact model limits")
            | issues
          ]
        end

      _limits ->
        issues
    end
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_interval(issues, callbacks, path, contact),
    do: apply(Keyword.fetch!(callbacks, :validate_interval), [issues, path, contact])

  defp validate_contact_fields(issues, callbacks, path, contact),
    do: apply(Keyword.fetch!(callbacks, :validate_contact_fields), [issues, path, contact])

  defp proposed_contact_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :proposed_contact_model_limits), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
