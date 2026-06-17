defmodule OrbitalDynamics.CampaignPlanner.RecommendationObjective do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{id: branch_id, objective_satisfaction: objective_satisfaction}) do
    objective_satisfaction = stringify_keys(objective_satisfaction || %{})

    priority_rows =
      objective_satisfaction
      |> Map.get("priority_commitments", %{})
      |> then(fn commitments ->
        [
          %{
            "type" => "objective_satisfaction",
            "objective" => "priority_commitments",
            "recommended_branch_id" => branch_id,
            "satisfied_target_ids" => Map.get(commitments, "satisfied_target_ids", []),
            "missed_target_ids" => Map.get(commitments, "missed_target_ids", [])
          }
          |> Map.merge(priority_commitment_fields(objective_satisfaction))
          |> compact_map()
        ]
      end)

    downlink_completion_rows =
      case Map.get(objective_satisfaction, "downlink_completion") do
        %{} ->
          [
            %{
              "type" => "objective_satisfaction",
              "objective" => "downlink_completion",
              "recommended_branch_id" => branch_id
            }
            |> Map.merge(downlink_completion_fields(objective_satisfaction))
            |> compact_map()
          ]

        _other ->
          []
      end

    coverage_rows =
      case Map.get(objective_satisfaction, "coverage") do
        %{} ->
          [
            %{
              "type" => "objective_satisfaction",
              "objective" => "coverage",
              "recommended_branch_id" => branch_id
            }
            |> Map.merge(coverage_fields(objective_satisfaction))
            |> compact_map()
          ]

        _other ->
          []
      end

    revisit_rows =
      case Map.get(objective_satisfaction, "revisit") do
        %{} ->
          [
            %{
              "type" => "objective_satisfaction",
              "objective" => "revisit",
              "recommended_branch_id" => branch_id
            }
            |> Map.merge(revisit_fields(objective_satisfaction))
            |> compact_map()
          ]

        _other ->
          []
      end

    collection_latency_rows =
      case Map.get(objective_satisfaction, "collection_latency") do
        %{} = collection_latency ->
          [
            %{
              "type" => "objective_satisfaction",
              "objective" => "collection_latency",
              "recommended_branch_id" => branch_id,
              "ratio" => Map.get(collection_latency, "ratio"),
              "observation_count" => Map.get(collection_latency, "observation_count"),
              "satisfied_observation_count" =>
                Map.get(collection_latency, "satisfied_observation_count"),
              "unsatisfied_observation_count" =>
                Map.get(collection_latency, "unsatisfied_observation_count")
            }
            |> Map.merge(collection_latency_fields(objective_satisfaction))
            |> compact_map()
          ]

        _other ->
          []
      end

    priority_rows ++
      downlink_completion_rows ++
      coverage_rows ++
      revisit_rows ++
      collection_latency_rows
  end

  def rows(_branch), do: []

  def comparison_fields(nil), do: %{}

  def comparison_fields(objective_satisfaction) do
    objective_satisfaction = stringify_keys(objective_satisfaction || %{})

    %{}
    |> Map.merge(priority_commitment_fields(objective_satisfaction))
    |> Map.merge(downlink_completion_fields(objective_satisfaction))
    |> Map.merge(coverage_fields(objective_satisfaction))
    |> Map.merge(revisit_fields(objective_satisfaction))
    |> Map.merge(collection_latency_fields(objective_satisfaction))
  end

  defp priority_commitment_fields(objective_satisfaction) do
    case Map.get(objective_satisfaction, "priority_commitments") do
      %{} = priority_commitments ->
        required = Map.get(priority_commitments, "required_target_ids", [])
        satisfied = Map.get(priority_commitments, "satisfied_target_ids", [])
        missed = Map.get(priority_commitments, "missed_target_ids", [])

        %{
          "priority_commitment_required_target_count" => length(required),
          "priority_commitment_satisfied_target_count" => length(satisfied),
          "priority_commitment_missed_target_count" => length(missed),
          "priority_commitment_required_target_ids" => required,
          "priority_commitment_satisfied_target_ids" => satisfied,
          "priority_commitment_missed_target_ids" => missed,
          "priority_commitment_required_observation_count" =>
            Map.get(priority_commitments, "required_observation_count"),
          "priority_commitment_planned_observation_count" =>
            Map.get(priority_commitments, "planned_observation_count"),
          "priority_commitment_missing_observation_count" =>
            Map.get(priority_commitments, "missing_observation_count"),
          "priority_commitment_ratio" => Map.get(priority_commitments, "ratio")
        }
        |> compact_map()

      _other ->
        %{}
    end
  end

  defp downlink_completion_fields(objective_satisfaction) do
    case Map.get(objective_satisfaction, "downlink_completion") do
      %{} = downlink_completion ->
        %{
          "downlink_completion_required_contacts" =>
            Map.get(downlink_completion, "required_contacts"),
          "downlink_completion_planned_contacts" =>
            Map.get(downlink_completion, "planned_contacts"),
          "downlink_completion_required_downlink_mb" =>
            Map.get(downlink_completion, "required_downlink_mb"),
          "downlink_completion_planned_downlink_mb" =>
            Map.get(downlink_completion, "planned_downlink_mb"),
          "downlink_completion_ratio" => Map.get(downlink_completion, "ratio")
        }
        |> compact_map()

      _other ->
        %{}
    end
  end

  defp coverage_fields(objective_satisfaction) do
    case Map.get(objective_satisfaction, "coverage") do
      %{} = coverage ->
        %{
          "coverage_observed_target_count" => Map.get(coverage, "observed_target_count")
        }
        |> compact_map()

      _other ->
        %{}
    end
  end

  defp revisit_fields(objective_satisfaction) do
    case Map.get(objective_satisfaction, "revisit") do
      %{} = revisit ->
        %{"revisit_count" => Map.get(revisit, "revisit_count")}
        |> compact_map()

      _other ->
        %{}
    end
  end

  defp collection_latency_fields(objective_satisfaction) do
    case Map.get(objective_satisfaction, "collection_latency") do
      %{} = collection_latency ->
        %{
          "collection_latency_ratio" => Map.get(collection_latency, "ratio"),
          "collection_latency_objective_count" => Map.get(collection_latency, "objective_count"),
          "collection_latency_observation_count" =>
            Map.get(collection_latency, "observation_count"),
          "collection_latency_satisfied_observation_count" =>
            Map.get(collection_latency, "satisfied_observation_count"),
          "collection_latency_unsatisfied_observation_count" =>
            Map.get(collection_latency, "unsatisfied_observation_count")
        }
        |> compact_map()

      _other ->
        %{}
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
