defmodule OrbitalDynamics.CampaignPlanner.RepairSourceFilterPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def suppressed_count(%{"suppressed_candidates" => rows}) when is_list(rows),
    do: length(rows)

  def suppressed_count(%{"suppressed_candidate_count" => count}) when is_number(count),
    do: trunc(count)

  def suppressed_count(_report), do: 0

  def candidate_rejection_count(report),
    do: candidate_rejection_count(report, &ValueEncoding.stringify_keys/1)

  def candidate_rejection_count(%{"rows" => rows}, stringify_keys)
      when is_list(rows) and is_function(stringify_keys, 1) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
    |> Enum.count(&(Map.get(&1, "rejection_status", "rejected") == "rejected"))
  end

  def candidate_rejection_count(
        %{"rejected_candidate_ids" => rejected_ids},
        _stringify_keys
      )
      when is_list(rejected_ids) do
    rejected_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> length()
  end

  def candidate_rejection_count(
        %{"rejected_candidate_count" => count},
        _stringify_keys
      )
      when is_number(count) and count > 0,
      do: trunc(count)

  def candidate_rejection_count(_report, _stringify_keys), do: 0
end
