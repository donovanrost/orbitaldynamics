defmodule OrbitalDynamics.Schema.CampaignRepairCandidatePoolContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityIdentity

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @source_field "source_candidate_activities"
  @suppressed_field "source_suppressed_candidate_activities"

  def validate(issues, %{} = artifact) do
    if Map.has_key?(artifact, @suppressed_field) do
      source_candidates = Map.get(artifact, @source_field)
      suppressed_candidates = Map.get(artifact, @suppressed_field)

      validate_partition(issues, artifact, source_candidates, suppressed_candidates)
    else
      issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp validate_partition(issues, artifact, source_candidates, suppressed_candidates)
       when is_list(source_candidates) and is_list(suppressed_candidates) do
    source_ids = candidate_ids(source_candidates)
    suppressed_ids = candidate_ids(suppressed_candidates)

    issues
    |> reject_empty_suppressed(suppressed_candidates)
    |> validate_unique_ids(@source_field, source_ids)
    |> validate_unique_ids(@suppressed_field, suppressed_ids)
    |> validate_disjoint_ids(source_ids, suppressed_ids)
    |> validate_source_count(artifact, length(source_candidates) + length(suppressed_candidates))
  end

  defp validate_partition(issues, _artifact, _source_candidates, _suppressed_candidates),
    do: issues

  defp candidate_ids(candidates) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.map(&ActivityIdentity.activity_id/1)
  end

  defp reject_empty_suppressed(issues, []),
    do: [error("$.#{@suppressed_field}", "must be omitted instead of empty") | issues]

  defp reject_empty_suppressed(issues, _candidates), do: issues

  defp validate_unique_ids(issues, field, ids) do
    if length(ids) == length(Enum.uniq(ids)) do
      issues
    else
      [error("$.#{field}", "must contain unique candidate IDs") | issues]
    end
  end

  defp validate_disjoint_ids(issues, source_ids, suppressed_ids) do
    if MapSet.disjoint?(MapSet.new(source_ids), MapSet.new(suppressed_ids)) do
      issues
    else
      [
        error(
          "$.#{@suppressed_field}",
          "must not overlap source_candidate_activities candidate IDs"
        )
        | issues
      ]
    end
  end

  defp validate_source_count(issues, artifact, partition_count) do
    path = "$.repair_metadata.candidate_source.candidate_count"
    candidate_count = get_in(artifact, ["repair_metadata", "candidate_source", "candidate_count"])

    if is_integer(candidate_count) and candidate_count != partition_count do
      [error(path, "must equal eligible plus suppressed candidate count") | issues]
    else
      issues
    end
  end
end
