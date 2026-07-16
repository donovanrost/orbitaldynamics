defmodule OrbitalDynamics.CampaignPlanner.ObjectivePressureRows do
  @moduledoc false

  def gap_status?(status),
    do: status in ["partial", "unmet", "candidate_available", "no_candidate_window"]

  def normalize_satisfaction_status(row, callbacks) do
    case row_status_value(row, callbacks) do
      status when status in [nil, ""] ->
        row

      status ->
        source_status = status_label(status)
        normalized_status = status(status)

        row
        |> put_if_present("status", normalized_status)
        |> put_source_objective_status(source_status, normalized_status)
    end
  end

  def normalize(row) do
    row
    |> normalize_field("objective")
    |> normalize_field("objective_type")
  end

  def label(label) when is_atom(label) do
    label
    |> Atom.to_string()
    |> label()
  end

  def label(label) when is_binary(label) do
    label
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def label(label), do: label

  defp put_source_objective_status(row, source_status, normalized_status) do
    if source_status in [nil, "", normalized_status] do
      row
    else
      Map.put(row, "_source_objective_status", source_status)
    end
  end

  defp row_status_value(row, callbacks) do
    [
      row["status"],
      row["objective_status"],
      row["satisfaction_status"],
      row["objective_satisfaction_status"],
      row["completion_status"],
      row["requirement_status"],
      row["downlink_requirement_status"],
      row["contact_requirement_status"],
      row["data_volume_requirement_status"],
      row["coverage_status"],
      row["coverage_requirement_status"],
      row["target_requirement_status"],
      row["target_coverage_status"],
      row["latency_status"],
      row["collection_latency_status"],
      row["delivery_status"],
      row["delivery_requirement_status"],
      row["source_objective_status"]
    ]
    |> Enum.find(fn value -> value not in [nil, ""] end)
    |> case do
      nil -> boolean_status(row, callbacks)
      status -> status
    end
  end

  defp boolean_status(row, callbacks) do
    json_boolean_value = Keyword.fetch!(callbacks, :json_boolean_value)

    [
      row["satisfied"],
      row["satisfied?"],
      row["objective_satisfied"],
      row["objective_satisfied?"],
      row["requirement_satisfied"],
      row["requirement_satisfied?"],
      row["downlink_requirement_satisfied"],
      row["downlink_requirement_satisfied?"],
      row["contact_requirement_satisfied"],
      row["contact_requirement_satisfied?"],
      row["data_volume_requirement_satisfied"],
      row["data_volume_requirement_satisfied?"],
      row["coverage_satisfied"],
      row["coverage_satisfied?"],
      row["target_satisfied"],
      row["target_satisfied?"],
      row["latency_satisfied"],
      row["latency_satisfied?"],
      row["delivery_satisfied"],
      row["delivery_satisfied?"],
      row["met"],
      row["met?"],
      row["objective_met"],
      row["objective_met?"]
    ]
    |> Enum.find_value(fn value ->
      case json_boolean_value.(value) do
        true -> "met"
        false -> "unmet"
        nil -> nil
      end
    end)
  end

  defp normalize_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, label(value))
    end
  end

  defp status(status) when is_boolean(status), do: if(status, do: "met", else: "unmet")

  defp status(status) when is_atom(status),
    do: status |> status_label() |> status()

  defp status(status) when is_binary(status) do
    case status_label(status) do
      status when status in ["satisfied", "complete", "completed"] ->
        "met"

      status when status in ["unsatisfied", "not_satisfied", "not_met", "missing"] ->
        "unmet"

      status when status in ["missed", "failed", "late", "overdue", "violated", "breached"] ->
        "unmet"

      status
      when status in [
             "shortfall",
             "insufficient",
             "below_target",
             "below_threshold",
             "under_target",
             "under_threshold",
             "gap",
             "has_gap",
             "at_risk",
             "needs_replan",
             "needs_refresh",
             "requires_attention",
             "degraded",
             "behind_plan"
           ] ->
        "partial"

      status
      when status in ["candidate_found", "candidate_window_available", "viable_candidate"] ->
        "candidate_available"

      status when status in ["no_candidate", "no_window", "no_viable_candidate"] ->
        "no_candidate_window"

      status ->
        status
    end
  end

  defp status(status), do: status

  defp status_label(status) when is_boolean(status), do: if(status, do: "met", else: "unmet")

  defp status_label(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> status_label()
  end

  defp status_label(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp status_label(status), do: status

  defp put_if_present(map, _key, value) when value in [nil, "", [], %{}], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
