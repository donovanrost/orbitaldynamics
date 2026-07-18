defmodule OrbitalDynamics.Timeline.CandidateRejectionSummaryPolicy do
  @moduledoc false

  def reason_counts(rows) do
    rows
    |> Enum.flat_map(& &1["rejection_reasons"])
    |> Enum.frequencies()
  end

  def candidate_rejection_row_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(& &1["candidate_id"])
    |> sorted_uniq()
  end

  def candidate_id_sets_by_rejection_reason(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("rejection_reasons", [])
      |> Enum.map(&{&1, row["candidate_id"]})
    end)
    |> Enum.group_by(fn {reason, _candidate_id} -> reason end, fn {_reason, candidate_id} ->
      candidate_id
    end)
    |> Map.new(fn {reason, candidate_ids} -> {reason, sorted_uniq(candidate_ids)} end)
  end

  def candidate_ids_by_required_operator_action(rows) do
    rows
    |> Enum.group_by(& &1["required_operator_action"], & &1["candidate_id"])
    |> Map.new(fn {action, candidate_ids} -> {action, sorted_uniq(candidate_ids)} end)
  end

  defp sorted_uniq(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
