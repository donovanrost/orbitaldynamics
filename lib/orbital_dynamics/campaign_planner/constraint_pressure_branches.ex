defmodule OrbitalDynamics.CampaignPlanner.ConstraintPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ConstraintDownlinkShortfallPressureEvents
  alias OrbitalDynamics.CampaignPlanner.ConstraintResourceMarginPressureEvents
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def branch(row, source_path, index), do: branch(row, source_path, index, callbacks())

  def branch(row, source_path, index, callbacks) do
    row = normalize(row, callbacks)

    row
    |> pressure_events(source_path, callbacks)
    |> Enum.map(fn event ->
      identity = row["constraint_id"] || event["resource_field"] || event["type"] || index

      %{
        "id" => "derived_constraint_pressure_#{branch_id_fragment(identity, callbacks)}",
        "label" => "Derived constraint pressure #{identity}",
        "events" => [event],
        "metadata" =>
          %{
            "derived_source" => source_path,
            "constraint_id" => row["constraint_id"],
            "constraint_status" => row["status"]
          }
          |> compact_map(callbacks)
      }
    end)
  end

  defp normalize(row, callbacks) do
    row
    |> normalize_field("status", callbacks)
    |> normalize_field("violation_severity", callbacks)
    |> normalize_field("metric", callbacks)
  end

  defp normalize_field(row, field, callbacks) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, normalized_status_token(value, callbacks))
    end
  end

  defp callbacks do
    [
      pressure_events: &pressure_events/2,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      normalized_status_token: &ScalarValues.normalized_status_token/1
    ]
  end

  defp pressure_events(row, source_path) do
    resource_margin_events = ConstraintResourceMarginPressureEvents.events(row, source_path)

    cond do
      row["status"] not in ["fail", "warning"] ->
        []

      resource_margin_events != [] ->
        resource_margin_events

      true ->
        ConstraintDownlinkShortfallPressureEvents.events(row, source_path)
    end
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp pressure_events(row, source_path, callbacks),
    do: callback(callbacks, :pressure_events, [row, source_path])

  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp branch_id_fragment(value, callbacks), do: callback(callbacks, :branch_id_fragment, [value])

  defp normalized_status_token(value, callbacks),
    do: callback(callbacks, :normalized_status_token, [value])
end
