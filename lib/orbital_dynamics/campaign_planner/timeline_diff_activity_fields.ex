defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffActivityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ScoreTermIdentifiers, ValueEncoding}

  def replacement_evidence(row), do: replacement_evidence(row, default_callbacks())

  def replacement_evidence(row, callbacks) do
    row_context = callback!(callbacks, :stringify_keys).(row)

    replacement_context =
      callback!(callbacks, :stringify_keys).(row["replacement_activity_context"] || %{})

    Map.merge(row_context, replacement_context)
    |> put_replacement_status(row_context)
  end

  def scenario_id(row) do
    row["scenario_id"] ||
      get_in(row, ["replacement_activity_context", "scenario_id"]) ||
      get_in(row, ["source_activity_context", "scenario_id"])
  end

  def ground_station_id(row), do: ground_station_id(row, default_callbacks())

  def ground_station_id(row, callbacks) do
    replacement_context = Map.get(row, "replacement_activity_context", %{})
    source_context = Map.get(row, "source_activity_context", %{})

    [
      row["replacement_ground_station_id"],
      row["source_ground_station_id"],
      callback!(callbacks, :score_term_entity_id).(row["replacement_ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(row["source_ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      get_in(row, ["replacement_activity_context", "ground_station_id"]),
      get_in(row, ["replacement_activity_context", "station_id"]),
      get_in(row, ["source_activity_context", "ground_station_id"]),
      get_in(row, ["source_activity_context", "station_id"]),
      callback!(callbacks, :score_term_entity_id).(replacement_context["ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(replacement_context["station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(source_context["ground_station"], [
        "ground_station_id",
        "station_id",
        "id"
      ]),
      callback!(callbacks, :score_term_entity_id).(source_context["station"], [
        "ground_station_id",
        "station_id",
        "id"
      ])
    ]
    |> Enum.find(&callback!(callbacks, :stable_id_string?).(&1))
  end

  def window_start_s(row), do: window_start_s(row, default_callbacks())

  def window_start_s(row, callbacks) do
    [
      row["replacement_starts_at_s"],
      row["starts_at_s"],
      get_in(row, ["replacement_activity_context", "starts_at_s"]),
      get_in(row, ["replacement_activity_context", "start_s"]),
      row["source_starts_at_s"],
      get_in(row, ["source_activity_context", "starts_at_s"]),
      get_in(row, ["source_activity_context", "start_s"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def window_end_s(row), do: window_end_s(row, default_callbacks())

  def window_end_s(row, callbacks) do
    [
      row["replacement_ends_at_s"],
      row["ends_at_s"],
      get_in(row, ["replacement_activity_context", "ends_at_s"]),
      get_in(row, ["replacement_activity_context", "end_s"]),
      row["source_ends_at_s"],
      get_in(row, ["source_activity_context", "ends_at_s"]),
      get_in(row, ["source_activity_context", "end_s"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def required_contacts(row), do: required_contacts(row, default_callbacks())

  def required_contacts(row, callbacks) do
    [
      row["required_contacts"],
      row["replacement_required_contacts"],
      get_in(row, ["replacement_activity_context", "required_contacts"]),
      get_in(row, ["replacement_activity_context", "required_contact_count"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 1
    end
  end

  def planned_contacts(row), do: planned_contacts(row, default_callbacks())

  def planned_contacts(row, callbacks) do
    [
      row["planned_contacts"],
      row["replacement_planned_contacts"],
      get_in(row, ["replacement_activity_context", "planned_contacts"]),
      get_in(row, ["replacement_activity_context", "planned_contact_count"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> value
      _value -> 0
    end
  end

  def changed_source_activity_ids(row),
    do: changed_source_activity_ids(row, default_callbacks())

  def changed_source_activity_ids(row, callbacks) do
    [
      row["source_activity_id"],
      row["replacement_activity_id"],
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["replacement_activity_context", "activity_id"])
    ]
    |> stable_ids(callbacks)
  end

  def source_activity_ids(row), do: source_activity_ids(row, default_callbacks())

  def source_activity_ids(row, callbacks) do
    [
      row["source_activity_id"],
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_timeline_identity", "activity_id"])
    ]
    |> stable_ids(callbacks)
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp stable_ids(values, callbacks) do
    values
    |> Enum.filter(&callback!(callbacks, :stable_id_string?).(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp put_replacement_status(evidence, row_context) do
    cond do
      is_binary(evidence["status"]) and evidence["status"] != "" ->
        evidence

      is_binary(row_context["replacement_status"]) and row_context["replacement_status"] != "" ->
        Map.put(evidence, "status", row_context["replacement_status"])

      is_binary(get_in(row_context, ["status_transition", "to"])) and
          get_in(row_context, ["status_transition", "to"]) != "" ->
        Map.put(evidence, "status", get_in(row_context, ["status_transition", "to"]))

      true ->
        evidence
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
