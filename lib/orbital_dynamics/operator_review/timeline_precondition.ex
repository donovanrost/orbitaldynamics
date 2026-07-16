defmodule OrbitalDynamics.OperatorReview.TimelinePrecondition do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(summary) do
    {rows, source_artifact_id, provenance} = package_input(summary)

    build_package(
      rows,
      "timeline_activity_precondition_summary.v1",
      source_artifact_id,
      provenance
    )
  end

  def package_input(summary) do
    summary = stringify_keys(summary || %{})
    summary = Map.put_new(summary, "schema_contract", "timeline_activity_precondition_summary.v1")

    {
      rows(summary),
      Map.get(summary, "id") || Map.get(summary, "source") || Map.get(summary, "timeline_id") ||
        Map.get(summary, "activity_id") || "timeline_activity_precondition_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_timeline_activity_precondition_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.timeline_activity_precondition_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_activity_precondition_summary"])},
        {"candidate_refresh.mission_state.source_timeline_activity_precondition_summary",
         get_in(artifact, ["mission_state", "source_timeline_activity_precondition_summary"])},
        {"candidate_refresh.mission_state.timeline_activity_precondition_summary",
         get_in(artifact, ["mission_state", "timeline_activity_precondition_summary"])},
        {"candidate_refresh.source_timeline_activity_precondition_summary",
         artifact["source_timeline_activity_precondition_summary"]},
        {"candidate_refresh.timeline_activity_precondition_summary",
         artifact["timeline_activity_precondition_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  def source_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> rows("#{source}.summary")
  end

  def source_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "timeline_activity_precondition_summary.v1"} = summary,
         source
       ) do
    source_summary_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_precondition_summary",
       artifact["source_timeline_activity_precondition_summary"]},
      {"#{source}.timeline_activity_precondition_summary",
       artifact["timeline_activity_precondition_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def rows(%{} = summary, source \\ "timeline_activity_precondition_summary.summary") do
    summary = stringify_keys(summary)
    [review_row(summary, 1, source)]
  end

  defp review_row(summary, index, source) do
    subject_id = summary["timeline_id"] || summary["activity_id"]
    required_operator_action = required_operator_action(summary)
    reason = reason(summary)

    %{
      "id" => review_id(["timeline_activity_precondition", subject_id, index]),
      "review_type" => "timeline_activity_precondition_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => summary["timeline_id"],
      "activity_id" => summary["activity_id"],
      "activity_type" => summary["activity_type"],
      "precondition_status" => summary["precondition_status"],
      "blocked_precondition_count" => summary["blocked_precondition_count"],
      "review_precondition_count" => summary["review_precondition_count"],
      "blocked_precondition_types" => summary["blocked_precondition_types"],
      "review_precondition_types" => summary["review_precondition_types"],
      "preconditions" => summary["preconditions"],
      "dependency_activity_ids" => summary["dependency_activity_ids"],
      "dependency_timeline_ids" => summary["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => summary["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => summary["exclusive_with_timeline_ids"],
      "duplicate_dependency_activity_ids" => summary["duplicate_dependency_activity_ids"],
      "duplicate_dependency_timeline_ids" => summary["duplicate_dependency_timeline_ids"],
      "duplicate_exclusivity_activity_ids" => summary["duplicate_exclusivity_activity_ids"],
      "duplicate_exclusivity_timeline_ids" => summary["duplicate_exclusivity_timeline_ids"],
      "allow_overlap" => summary["allow_overlap"],
      "invalid_activity_input" => summary["invalid_activity_input"],
      "invalid_activity_input_reason" => summary["invalid_activity_input_reason"],
      "timeline_identity" => summary["timeline_identity"],
      "action" => required_operator_action,
      "required_operator_action" => required_operator_action,
      "approval_status" => approval_status(summary),
      "reason" => reason,
      "operator_action_reason" => reason,
      "source_timeline_activity_precondition_summary" => summary
    }
    |> compact_map()
  end

  defp required_operator_action(%{"invalid_activity_input" => true}),
    do: "review_invalid_activity_input"

  defp required_operator_action(%{"precondition_status" => "blocked"}),
    do: "review_blocked_activity_precondition"

  defp required_operator_action(%{"precondition_status" => "review_required"}),
    do: "review_activity_precondition"

  defp required_operator_action(%{"precondition_status" => "clear"}),
    do: "record_activity_precondition"

  defp required_operator_action(_summary), do: "review_activity_precondition"

  defp approval_status(%{"precondition_status" => "clear"}), do: "not_required"
  defp approval_status(_summary), do: "operator_review_required"

  defp reason(%{"invalid_activity_input" => true} = summary) do
    summary["invalid_activity_input_reason"] || "invalid_activity_input"
  end

  defp reason(%{"precondition_status" => "blocked"}), do: "blocked_activity_precondition"

  defp reason(%{"precondition_status" => "review_required"}),
    do: "activity_precondition_review_required"

  defp reason(%{"precondition_status" => "clear"}), do: "activity_precondition_clear"
  defp reason(_summary), do: "activity_precondition_review_required"

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
