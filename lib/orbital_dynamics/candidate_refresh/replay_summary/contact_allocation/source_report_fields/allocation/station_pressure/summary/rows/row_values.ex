defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.Availability
  alias __MODULE__.Normalization

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&normalize_row(stringify_keys(&1)))
    |> Enum.filter(&Availability.station_pressure?/1)
  end

  def review_row?(row) do
    row["review_status"] == "operator_review_required" or
      row["allocation_status"] in ["blocked", "deferred"] or
      row["effective_allocation_status"] == "policy_blocked"
  end

  defdelegate availability_values(row), to: Availability

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

  def group_key(row, field), do: stable_id_or_nil(row[field]) || normalized_token(row[field])

  def summary_contact_id(row) do
    stable_id_or_nil(row["contact_id"]) ||
      stable_id_or_nil(row["id"]) ||
      stable_id_or_nil(get_in(row, ["activity_context", "activity_id"]))
  end

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)

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

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
