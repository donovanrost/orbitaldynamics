defmodule OrbitalDynamics.CampaignPlanner.StrategyPriorPlanCandidates do
  @moduledoc false

  def normalize(prior_plan, callbacks) when is_list(callbacks) do
    prior_plan = stringify_keys(prior_plan || %{})

    if v2_repair_artifact?(prior_plan) do
      source_candidates = source_candidate_activities(prior_plan, callbacks)

      if source_candidates in [nil, []] do
        raise ArgumentError,
              "V3 strategy with a V2 repair artifact requires source_candidate_activities"
      end

      Map.put(prior_plan, "candidate_activities", source_candidates)
    else
      prior_plan
    end
  end

  def source_candidate_activities(prior_plan, callbacks) when is_list(callbacks) do
    candidate_activity_rows(
      prior_plan,
      ["source_candidate_activities", "candidate_activities"],
      callbacks
    )
  end

  def candidate_activities(prior_plan, callbacks) when is_list(callbacks) do
    candidate_activity_rows(
      prior_plan,
      ["candidate_activities", "source_candidate_activities"],
      callbacks
    )
  end

  defp candidate_activity_rows(prior_plan, fields, callbacks) do
    prior_plan = stringify_keys(prior_plan || %{})

    case first_candidate_activity_rows(prior_plan, fields) do
      [] -> result_artifact_candidate_activity_rows(prior_plan, fields, callbacks)
      rows -> normalize_candidate_activity_rows(rows)
    end
  end

  defp result_artifact_candidate_activity_rows(prior_plan, fields, callbacks) do
    result_artifacts_with_source = Keyword.fetch!(callbacks, :result_artifacts_with_source)
    put_inherited_trust_boundary = Keyword.fetch!(callbacks, :put_inherited_trust_boundary)

    prior_plan
    |> result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, _source_path} ->
      artifact
      |> first_candidate_activity_rows(fields)
      |> normalize_candidate_activity_rows()
      |> Enum.map(&put_inherited_trust_boundary.(&1, artifact))
    end)
  end

  defp first_candidate_activity_rows(source, fields) do
    Enum.find_value(fields, [], fn field ->
      rows = candidate_activity_rows(Map.get(source, field))

      if rows == [] do
        nil
      else
        rows
      end
    end)
  end

  defp candidate_activity_rows(rows) when is_list(rows), do: rows
  defp candidate_activity_rows(_rows), do: []

  defp normalize_candidate_activity_rows(rows) do
    Enum.map(rows, &stringify_keys/1)
  end

  defp v2_repair_artifact?(prior_plan) do
    Map.get(prior_plan, "schema_version") == 2 or
      Map.get(prior_plan, "planner") == "OrbitalDynamics.CampaignPlanner.V2"
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
