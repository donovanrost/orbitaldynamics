defmodule OrbitalDynamics.CampaignPlanner.DirectOperationalFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    OperationalFeedbackNormalization,
    OperationalFeedbackSourceMetadata,
    ValueEncoding
  }

  def prior_plan_feedback(prior_plan), do: prior_plan_feedback(prior_plan, default_callbacks())

  def prior_plan_feedback(prior_plan, callbacks) do
    prior_plan
    |> prior_plan_sources(callbacks)
    |> feedback_from_sources(callbacks)
  end

  def prior_plan_metadata(prior_plan), do: prior_plan_metadata(prior_plan, default_callbacks())

  def prior_plan_metadata(prior_plan, callbacks) do
    prior_plan
    |> prior_plan_sources(callbacks)
    |> metadata_from_sources(callbacks)
  end

  def prior_plan_sources(prior_plan), do: prior_plan_sources(prior_plan, default_callbacks())

  def prior_plan_sources(prior_plan, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    result_artifacts_with_source =
      Keyword.fetch!(callbacks, :prior_plan_result_artifacts_with_source)

    prior_plan = stringify_keys.(prior_plan || %{})

    direct_sources =
      case Map.fetch(prior_plan, "operational_feedback") do
        {:ok, feedback} -> [{feedback, "prior_plan.operational_feedback"}]
        :error -> []
      end

    result_artifact_sources =
      prior_plan
      |> result_artifacts_with_source.()
      |> Enum.flat_map(fn {artifact, source_path} ->
        case Map.fetch(artifact, "operational_feedback") do
          {:ok, feedback} -> [{feedback, "#{source_path}.operational_feedback"}]
          :error -> []
        end
      end)

    direct_sources ++ result_artifact_sources
  end

  def mission_state_feedback(mission_state),
    do: mission_state_feedback(mission_state, default_callbacks())

  def mission_state_feedback(mission_state, callbacks) do
    mission_state
    |> mission_state_sources(callbacks)
    |> feedback_from_sources(callbacks)
  end

  def mission_state_metadata(mission_state),
    do: mission_state_metadata(mission_state, default_callbacks())

  def mission_state_metadata(mission_state, callbacks) do
    mission_state
    |> mission_state_sources(callbacks)
    |> metadata_from_sources(callbacks)
  end

  def mission_state_sources(mission_state),
    do: mission_state_sources(mission_state, default_callbacks())

  def mission_state_sources(mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    result_artifacts_with_source =
      Keyword.fetch!(callbacks, :mission_state_result_artifacts_with_source)

    mission_state = stringify_keys.(mission_state || %{})

    direct_sources =
      case Map.fetch(mission_state, "operational_feedback") do
        {:ok, feedback} when is_map(feedback) and map_size(feedback) > 0 ->
          [{feedback, "mission_state.operational_feedback"}]

        {:ok, feedback} when not is_map(feedback) ->
          [{feedback, "mission_state.operational_feedback"}]

        {:ok, _feedback} ->
          []

        :error ->
          []
      end

    result_artifact_sources =
      mission_state
      |> result_artifacts_with_source.()
      |> Enum.flat_map(fn {artifact, source_path} ->
        case Map.fetch(artifact, "operational_feedback") do
          {:ok, feedback} -> [{feedback, "#{source_path}.operational_feedback"}]
          :error -> []
        end
      end)

    direct_sources ++ result_artifact_sources
  end

  defp feedback_from_sources(sources, callbacks) do
    normalize_operational_feedback = Keyword.fetch!(callbacks, :normalize_operational_feedback)
    merge_operational_feedback = Keyword.fetch!(callbacks, :merge_operational_feedback)

    sources
    |> Enum.filter(fn {feedback, _source_path} -> is_map(feedback) end)
    |> Enum.map(fn {feedback, _source_path} -> feedback end)
    |> case do
      [] ->
        sources
        |> Enum.map(fn {feedback, _source_path} -> feedback end)
        |> Enum.find(%{}, &(not is_nil(&1)))

      feedback_maps ->
        Enum.reduce(feedback_maps, normalize_operational_feedback.(%{}), fn feedback, merged ->
          merge_operational_feedback.(merged, feedback)
        end)
    end
  end

  defp metadata_from_sources(sources, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    trust_boundary_summary = Keyword.fetch!(callbacks, :trust_boundary_summary)

    inferred_feedback_trust_boundaries =
      Keyword.fetch!(callbacks, :inferred_feedback_trust_boundaries)

    merge_feedback_trust_boundary_maps =
      Keyword.fetch!(callbacks, :merge_feedback_trust_boundary_maps)

    source_paths =
      sources
      |> Enum.map(fn {_feedback, source_path} -> source_path end)
      |> Enum.uniq()

    feedback_maps =
      sources
      |> Enum.map(fn {feedback, _source_path} -> feedback end)
      |> Enum.filter(&is_map/1)

    trust_boundaries =
      feedback_maps
      |> Enum.flat_map(fn feedback ->
        summary = trust_boundary_summary.(feedback)
        summary |> Map.get("trust_boundaries") |> List.wrap()
      end)
      |> Enum.uniq()
      |> Enum.sort()

    feedback_trust_boundaries =
      feedback_maps
      |> Enum.flat_map(fn feedback ->
        summary = trust_boundary_summary.(feedback)

        [
          Map.get(summary, "feedback_trust_boundaries"),
          inferred_feedback_trust_boundaries.(feedback)
        ]
      end)
      |> merge_feedback_trust_boundary_maps.()
      |> case do
        boundaries when boundaries == %{} -> nil
        boundaries -> boundaries
      end

    %{
      "source_report_paths" => if(source_paths == [], do: nil, else: source_paths),
      "trust_boundary_status" => if(trust_boundaries == [], do: nil, else: "declared"),
      "trust_boundaries" => if(trust_boundaries == [], do: nil, else: trust_boundaries),
      "feedback_trust_boundaries" => feedback_trust_boundaries
    }
    |> compact_map.()
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      merge_operational_feedback: &OperationalFeedbackNormalization.merge/2,
      prior_plan_result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      mission_state_result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      trust_boundary_summary: &OperationalFeedbackSourceMetadata.trust_boundary_summary/1,
      inferred_feedback_trust_boundaries:
        &OperationalFeedbackSourceMetadata.inferred_feedback_trust_boundaries/1,
      merge_feedback_trust_boundary_maps:
        &OperationalFeedbackSourceMetadata.merge_feedback_trust_boundary_maps/1
    ]
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
  end

  defp mission_state_result_artifacts_with_source(mission_state) do
    BranchRefreshSourceInputs.result_artifacts_with_source(mission_state, "mission_state")
  end
end
