defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{TimelineSourceReports, ValueEncoding}

  def source(%{} = row), do: source(row, callbacks())

  def source(%{} = row, callbacks) do
    case application_source(row) do
      %{} = source when map_size(source) > 0 ->
        {source
         |> TimelineSourceReports.timeline_transition_application_pressure_row()
         |> review_row(row, row_shaping_callbacks(callbacks)), application_source_suffix(row)}

      _source ->
        source_review_source(row, callbacks)
    end
  end

  def source_review_source(%{"source_timeline_diff" => %{} = source} = row, callbacks)
      when map_size(source) > 0 do
    callbacks = row_shaping_callbacks(callbacks)

    {source |> callback!(callbacks, :stringify_keys).() |> review_row(row, callbacks),
     "source_timeline_diff"}
  end

  def source_review_source(row, callbacks) do
    callbacks = row_shaping_callbacks(callbacks)

    {row |> callback!(callbacks, :stringify_keys).() |> review_row(row, callbacks),
     "timeline_diff_review"}
  end

  def application_source(row) do
    cond do
      is_map(row["source_timeline_application"]) ->
        row["source_timeline_application"]

      is_map(row["source_timeline_transition_application"]) ->
        row["source_timeline_transition_application"]

      true ->
        nil
    end
  end

  def application_source_suffix(row) do
    if is_map(row["source_timeline_application"]) do
      "source_timeline_application"
    else
      "source_timeline_transition_application"
    end
  end

  def review_row(source, row), do: review_row(source, row, callbacks())

  def review_row(source, row, callbacks) do
    [
      "approval_status",
      "application_status",
      "selected_activity_source",
      "selected_activity",
      "policy_classification",
      "policy_bundle_id",
      "source_policy_decision",
      "approval_requirements",
      "approval_rule_matches",
      "required_operator_action",
      "trust_boundary",
      "provenance"
    ]
    |> Enum.reduce(callback!(callbacks, :stringify_keys).(source), fn field, acc ->
      callback!(callbacks, :put_default_if_present).(acc, field, row[field])
    end)
    |> callback!(callbacks, :put_default_if_present).(
      "source_policy_decision",
      row["policy_decision"]
    )
  end

  def review_row?(row) do
    (row["source_review_type"] == "timeline_diff_review" or
       row["review_type"] == "timeline_diff_review" or
       row["import_action"] == "review_timeline_diff") and
      row["diff_status"] not in [nil, ""] and
      (row["source_activity_id"] not in [nil, ""] or
         row["replacement_activity_id"] not in [nil, ""] or row["timeline_id"] not in [nil, ""])
  end

  def plan_delta_source(row), do: plan_delta_source(row, callbacks())

  def plan_delta_source(%{"source_delta" => %{} = source} = row, callbacks)
      when map_size(source) > 0,
      do: {plan_delta_row(source, row, callbacks), "source_delta"}

  def plan_delta_source(row, callbacks),
    do: {plan_delta_row(row, row, callbacks), "plan_delta_review"}

  def plan_delta_row(source, row), do: plan_delta_row(source, row, callbacks())

  def plan_delta_row(source, row, callbacks) do
    source = callback!(callbacks, :stringify_keys).(source)

    source_context =
      source["source_activity_context"] || row["source_activity_context"] ||
        source["planned"] || row["planned"] || %{}

    replacement_context =
      source["replacement_activity_context"] || row["replacement_activity_context"] ||
        source["replacement"] || row["replacement"] || %{}

    repair_action = source["repair_action"] || row["repair_action"]

    %{
      "id" => source["id"] || row["id"],
      "diff_status" => plan_delta_diff_status(repair_action),
      "repair_action" => repair_action,
      "timeline_id" => source["source_timeline_id"] || row["source_timeline_id"],
      "source_activity_id" => source["activity_id"] || row["activity_id"],
      "source_activity_type" => source["activity_type"] || row["activity_type"],
      "source_direction" => source["direction"] || source_context["direction"],
      "source_status" => source_context["status"] || source["source_status"],
      "source_activity_context" => source_context,
      "replacement_activity_id" =>
        source["replacement_activity_id"] || row["replacement_activity_id"],
      "replacement_activity_type" =>
        replacement_context["activity_type"] || replacement_context["type"],
      "replacement_direction" => replacement_context["direction"],
      "replacement_activity_context" => replacement_context,
      "required_operator_action" =>
        row["required_operator_action"] || source["required_operator_action"],
      "approval_status" => row["approval_status"] || source["approval_status"]
    }
    |> callback!(callbacks, :compact_map).()
  end

  def plan_delta_diff_status(action) when action in ["canceled", "cancelled", "suppressed"],
    do: "removed"

  def plan_delta_diff_status(action) when action in ["moved", "replaced"], do: "changed"
  def plan_delta_diff_status(_action), do: nil

  def plan_delta_row?(row) do
    (row["source_review_type"] == "plan_delta_review" or
       row["review_type"] == "plan_delta_review" or row["import_action"] == "review_plan_delta") and
      plan_delta_diff_status(row["repair_action"]) != nil
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp row_shaping_callbacks(callbacks) do
    callbacks()
    |> Keyword.merge(
      Keyword.take(callbacks, [:compact_map, :put_default_if_present, :stringify_keys])
    )
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      put_default_if_present: &put_default_if_present/3,
      stringify_keys: &ValueEncoding.stringify_keys/1
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
