defmodule OrbitalDynamics.CampaignPlanner.ContactIntentReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ContactIntentPressureBranches, ValueEncoding}

  @fields [
    "id",
    "activity_id",
    "contact_id",
    "activity_type",
    "type",
    "scenario_id",
    "spacecraft_id",
    "ground_station_id",
    "station_id",
    "direction",
    "starts_at_s",
    "ends_at_s",
    "estimated_throughput_mb",
    "required_downlink_mb",
    "planned_throughput_mb",
    "timeline_id",
    "timeline_identity",
    "source_window_id",
    "approval_status",
    "required_operator_action",
    "cadence_import_status",
    "invalid_cadence_import",
    "invalid_cadence_import_reason",
    "invalid_activity_input",
    "invalid_activity_input_reason",
    "schedule_conflict_status",
    "reason",
    "source_policy_decision",
    "approval_requirements",
    "approval_rule_matches",
    "activity_context",
    "trust_boundary",
    "provenance",
    "station_availability",
    "station_contention_status",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_calendar_directions",
    "station_calendar_status",
    "station_calendar_trust_boundary_status",
    "station_reservation_id",
    "station_reserved_by",
    "station_reservation_status",
    "station_reservation_match_status",
    "source_station_calendar_entry",
    "source_station_calendar_overlaps"
  ]

  def source(row), do: source(row, callbacks())

  def source(%{"source_contact_intent" => %{} = source} = row, callbacks)
      when map_size(source) > 0,
      do: {row(source, row, callbacks), "source_contact_intent"}

  def source(row, callbacks), do: {row(row, row, callbacks), "contact_intent_review"}

  def row(source, row), do: row(source, row, callbacks())

  def row(source, row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    put_default_if_present = Keyword.fetch!(callbacks, :put_default_if_present)

    @fields
    |> Enum.reduce(stringify_keys.(source), fn field, acc ->
      put_default_if_present.(acc, field, row[field])
    end)
    |> put_default_if_present.("type", row["activity_type"])
  end

  def review_row?(row, callbacks \\ review_callbacks()) do
    pressure_event = Keyword.fetch!(callbacks, :pressure_event)

    (row["source_review_type"] == "contact_intent_review" or
       row["review_type"] == "contact_intent_review" or
       row["import_action"] == "review_contact_intent") and
      pressure_event.(row, "candidate") != nil
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_default_if_present: &put_default_if_present/3
    ]
  end

  defp review_callbacks do
    [
      pressure_event: &ContactIntentPressureBranches.event/2
    ]
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, ""] -> Map.put(map, field, value)
      _existing -> map
    end
  end
end
