defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.{ContactMaps, Normalization}

  def rows_for_summary(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&normalize_row(stringify_keys(&1)))
  end

  def effective_status(row) do
    Map.get(row, "effective_allocation_status") ||
      Map.get(row, "allocation_status") ||
      Map.get(row, "approval_status") ||
      get_in(row, ["policy_decision", "classification"])
  end

  def invalid_contact_input_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(&(&1["invalid_contact_input"] == true))
  end

  def status_blocked_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(&status_blocked_row?/1)
  end

  def resource_blocked_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(&is_map(&1["source_resource_suppression"]))
  end

  def review_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(&review_row?/1)
  end

  def group_key(row, field) do
    stable_id_or_nil(row[field]) || normalized_token(row[field])
  end

  def duplicate_contact_row?(row) do
    row["duplicate_contact_id_collision"] in [true, "true"] or
      row["allocation_reason"] == "duplicate_contact_id" or
      row["suppressed_reason"] == "duplicate_contact_id"
  end

  def summary_contact_id(row) do
    stable_id_or_nil(row["contact_id"]) ||
      stable_id_or_nil(row["id"]) ||
      stable_id_or_nil(get_in(row, ["activity_context", "activity_id"]))
  end

  def summary_direction(row) do
    [
      row["direction"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "activity_context", "direction"]),
      get_in(row, ["source_contention_recommendation", "direction"]),
      row["type"],
      get_in(row, ["source_contact_candidate", "type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def map_value_lists(value), do: ContactMaps.map_value_lists(value)

  def id_map_counts(contact_ids_by_key), do: ContactMaps.id_map_counts(contact_ids_by_key)

  def sorted_non_empty_values(values), do: ContactMaps.sorted_non_empty_values(values)

  def grouped_contact_ids(pairs), do: ContactMaps.grouped_contact_ids(pairs)

  def grouped_contact_counts(pairs), do: ContactMaps.grouped_contact_counts(pairs)

  def explicit_count_map(report, field) do
    case Map.get(report, field) do
      counts when is_map(counts) -> counts
      _counts -> nil
    end
  end

  def non_empty_map(map), do: ContactMaps.non_empty_map(map)

  def rows_matching_status(report, statuses) do
    report
    |> rows_for_summary()
    |> Enum.filter(fn row ->
      Enum.any?(statuses, fn {field, status} ->
        normalized_token(row[field]) == status
      end)
    end)
  end

  defp normalize_row(row) do
    row
    |> normalize_status_field("allocation_status")
    |> normalize_status_field("effective_allocation_status")
    |> normalize_status_field("review_status")
    |> normalize_status_field("approval_status")
    |> normalize_policy_decision()
  end

  defp normalize_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, normalized_token(value))
    end
  end

  defp normalize_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> stringify_keys()
      |> normalize_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_policy_decision(row), do: row

  defp status_blocked_row?(row) do
    case row["allocation_reason"] do
      reason when is_binary(reason) ->
        String.starts_with?(reason, "activity_status_") or
          String.starts_with?(reason, "approval_status_")

      _reason ->
        false
    end
  end

  defp review_row?(row) do
    row["review_status"] == "operator_review_required" or
      row["allocation_status"] in ["blocked", "deferred"] or
      row["effective_allocation_status"] == "policy_blocked"
  end

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
