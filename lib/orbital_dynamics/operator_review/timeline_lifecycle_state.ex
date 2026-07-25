defmodule OrbitalDynamics.OperatorReview.TimelineLifecycleState do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def summary_package(summary) do
    {rows, source_artifact_id, provenance} = summary_package_input(summary)

    build_package(rows, "timeline_lifecycle_state_summary.v1", source_artifact_id, provenance)
  end

  def activity_state_package(state) do
    activity_package(
      state,
      "timeline_activity_state.v1",
      "timeline_activity_state.state",
      "timeline_activity_state"
    )
  end

  def activity_status_state_package(state) do
    activity_package(
      state,
      "timeline_activity_status_state.v1",
      "timeline_activity_status_state.state",
      "timeline_activity_status_state"
    )
  end

  def activity_approval_state_package(state) do
    activity_package(
      state,
      "timeline_activity_approval_state.v1",
      "timeline_activity_approval_state.state",
      "timeline_activity_approval_state"
    )
  end

  def activity_lifecycle_state_package(state) do
    activity_package(
      state,
      "timeline_activity_lifecycle_state.v1",
      "timeline_activity_lifecycle_state.state",
      "timeline_activity_lifecycle_state"
    )
  end

  def summary_package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      summary_rows(summary),
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_lifecycle_state_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def candidate_refresh_summary_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_lifecycle_state_summary",
         get_in(artifact, ["accepted_planning_state", "source_timeline_lifecycle_state_summary"])},
        {"candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_lifecycle_state_summary"])},
        {"candidate_refresh.mission_state.source_timeline_lifecycle_state_summary",
         get_in(artifact, ["mission_state", "source_timeline_lifecycle_state_summary"])},
        {"candidate_refresh.mission_state.timeline_lifecycle_state_summary",
         get_in(artifact, ["mission_state", "timeline_lifecycle_state_summary"])},
        {"candidate_refresh.source_timeline_lifecycle_state_summary",
         artifact["source_timeline_lifecycle_state_summary"]},
        {"candidate_refresh.timeline_lifecycle_state_summary",
         artifact["timeline_lifecycle_state_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_summary_rows(artifact)
  end

  def candidate_refresh_activity_state_rows(artifact) do
    direct_rows =
      candidate_refresh_activity_state_sources(artifact)
      |> Enum.flat_map(fn {source, state_or_states} ->
        source_activity_state_rows(state_or_states, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_activity_state_rows(artifact)
  end

  def candidate_refresh_activity_lifecycle_state_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_activity_lifecycle_state",
         get_in(artifact, ["accepted_planning_state", "source_timeline_activity_lifecycle_state"])},
        {"candidate_refresh.accepted_planning_state.timeline_activity_lifecycle_state",
         get_in(artifact, ["accepted_planning_state", "timeline_activity_lifecycle_state"])},
        {"candidate_refresh.mission_state.source_timeline_activity_lifecycle_state",
         get_in(artifact, ["mission_state", "source_timeline_activity_lifecycle_state"])},
        {"candidate_refresh.mission_state.timeline_activity_lifecycle_state",
         get_in(artifact, ["mission_state", "timeline_activity_lifecycle_state"])},
        {"candidate_refresh.source_timeline_activity_lifecycle_state",
         artifact["source_timeline_activity_lifecycle_state"]},
        {"candidate_refresh.timeline_activity_lifecycle_state",
         artifact["timeline_activity_lifecycle_state"]}
      ]
      |> Enum.flat_map(fn {source, state_or_states} ->
        source_activity_lifecycle_state_rows(state_or_states, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_activity_lifecycle_state_rows(artifact)
  end

  def summary_rows(summary),
    do: summary_rows(summary, "timeline_lifecycle_state_summary.review_rows")

  def summary_rows(%{} = summary, source) do
    summary
    |> Map.get("review_rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      review_row(row, index, source, summary)
    end)
  end

  def summary_rows(_summary, _source), do: []

  def activity_state_rows(%{} = state, source) do
    [
      review_row(
        state,
        1,
        source,
        activity_state_summary(state)
      )
    ]
  end

  def activity_state_package_input(state, schema_contract, source, fallback) do
    state = stringify_keys(state || %{})
    state = Map.put_new(state, "schema_contract", schema_contract)

    {
      activity_state_rows(state, source),
      source_id(state, fallback),
      Map.get(state, "provenance", %{})
    }
  end

  def source_id(state, fallback) do
    Map.get(state, "id") || Map.get(state, "source") || Map.get(state, "timeline_id") ||
      Map.get(state, "activity_id") || fallback
  end

  defp source_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> summary_rows("#{source}.review_rows")
  end

  defp source_summary_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_summary_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_summary_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_summary_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_summary_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_summary_rows(
         %{"schema_contract" => "timeline_lifecycle_state_summary.v1"} = summary,
         source
       ) do
    source_summary_rows(summary, source)
  end

  defp result_artifact_summary_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_lifecycle_state_summary",
       artifact["source_timeline_lifecycle_state_summary"]},
      {"#{source}.timeline_lifecycle_state_summary", artifact["timeline_lifecycle_state_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_summary_rows(_artifact, _source), do: []

  defp candidate_refresh_activity_state_sources(artifact) do
    [
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_state"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_status_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_status_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_status_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_status_state"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_activity_approval_state",
       get_in(artifact, ["accepted_planning_state", "source_timeline_activity_approval_state"])},
      {"candidate_refresh.accepted_planning_state.timeline_activity_approval_state",
       get_in(artifact, ["accepted_planning_state", "timeline_activity_approval_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_state"])},
      {"candidate_refresh.mission_state.timeline_activity_state",
       get_in(artifact, ["mission_state", "timeline_activity_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_status_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_status_state"])},
      {"candidate_refresh.mission_state.timeline_activity_status_state",
       get_in(artifact, ["mission_state", "timeline_activity_status_state"])},
      {"candidate_refresh.mission_state.source_timeline_activity_approval_state",
       get_in(artifact, ["mission_state", "source_timeline_activity_approval_state"])},
      {"candidate_refresh.mission_state.timeline_activity_approval_state",
       get_in(artifact, ["mission_state", "timeline_activity_approval_state"])},
      {"candidate_refresh.source_timeline_activity_state",
       artifact["source_timeline_activity_state"]},
      {"candidate_refresh.timeline_activity_state", artifact["timeline_activity_state"]},
      {"candidate_refresh.source_timeline_activity_status_state",
       artifact["source_timeline_activity_status_state"]},
      {"candidate_refresh.timeline_activity_status_state",
       artifact["timeline_activity_status_state"]},
      {"candidate_refresh.source_timeline_activity_approval_state",
       artifact["source_timeline_activity_approval_state"]},
      {"candidate_refresh.timeline_activity_approval_state",
       artifact["timeline_activity_approval_state"]}
    ]
  end

  def source_activity_state_rows(states, source) when is_list(states) do
    states
    |> Enum.with_index()
    |> Enum.flat_map(fn {state, index} ->
      source_activity_state_rows(state, "#{source}[#{index}]")
    end)
  end

  def source_activity_state_rows(%{} = state, source) do
    state
    |> stringify_keys()
    |> activity_state_rows("#{source}.state")
  end

  def source_activity_state_rows(_state, _source), do: []

  defp candidate_refresh_result_artifact_activity_state_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_activity_state_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_activity_state_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_activity_state_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_activity_state_rows(
         %{"schema_contract" => schema_contract} = state,
         source
       )
       when schema_contract in [
              "timeline_activity_state.v1",
              "timeline_activity_status_state.v1",
              "timeline_activity_approval_state.v1"
            ] do
    source_activity_state_rows(state, source)
  end

  defp result_artifact_activity_state_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_state", artifact["source_timeline_activity_state"]},
      {"#{source}.timeline_activity_state", artifact["timeline_activity_state"]},
      {"#{source}.source_timeline_activity_status_state",
       artifact["source_timeline_activity_status_state"]},
      {"#{source}.timeline_activity_status_state", artifact["timeline_activity_status_state"]},
      {"#{source}.source_timeline_activity_approval_state",
       artifact["source_timeline_activity_approval_state"]},
      {"#{source}.timeline_activity_approval_state", artifact["timeline_activity_approval_state"]}
    ]
    |> Enum.flat_map(fn {state_source, state_or_states} ->
      source_activity_state_rows(state_or_states, state_source)
    end)
  end

  defp result_artifact_activity_state_rows(_artifact, _source), do: []

  def source_activity_lifecycle_state_rows(states, source) when is_list(states) do
    states
    |> Enum.with_index()
    |> Enum.flat_map(fn {state, index} ->
      source_activity_lifecycle_state_rows(state, "#{source}[#{index}]")
    end)
  end

  def source_activity_lifecycle_state_rows(%{} = state, source) do
    state
    |> stringify_keys()
    |> activity_state_rows("#{source}.state")
  end

  def source_activity_lifecycle_state_rows(_state, _source), do: []

  defp candidate_refresh_result_artifact_activity_lifecycle_state_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_activity_lifecycle_state_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_activity_lifecycle_state_rows(artifacts, source)
       when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_activity_lifecycle_state_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_activity_lifecycle_state_rows(
         %{"schema_contract" => "timeline_activity_lifecycle_state.v1"} = state,
         source
       ) do
    source_activity_lifecycle_state_rows(state, source)
  end

  defp result_artifact_activity_lifecycle_state_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_activity_lifecycle_state",
       artifact["source_timeline_activity_lifecycle_state"]},
      {"#{source}.timeline_activity_lifecycle_state",
       artifact["timeline_activity_lifecycle_state"]}
    ]
    |> Enum.flat_map(fn {state_source, state_or_states} ->
      source_activity_lifecycle_state_rows(state_or_states, state_source)
    end)
  end

  defp result_artifact_activity_lifecycle_state_rows(_artifact, _source), do: []

  defp activity_state_summary(%{} = state) do
    if state["review_required"] do
      %{
        "planned_activity_count" => 1,
        "realized_activity_count" => 1,
        "review_required_count" => 1
      }
    else
      %{
        "planned_activity_count" => 1,
        "realized_activity_count" => 1,
        "review_required_count" => 0
      }
    end
  end

  defp review_row(row, index, source, summary) do
    subject_id = row["timeline_id"] || row["activity_id"]
    required_operator_action = required_operator_action(row)

    %{
      "id" => review_id(["timeline_lifecycle_state", subject_id, index]),
      "review_type" => "timeline_lifecycle_state_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "planned_activity_id" => row["planned_activity_id"],
      "realized_activity_id" => row["realized_activity_id"],
      "planned_activity_ids" => row["planned_activity_ids"],
      "realized_activity_ids" => row["realized_activity_ids"],
      "timeline_lifecycle_state_status" => "review_required",
      "transition_decision" => row["transition_decision"] || "review",
      "status_transition_decision" => row["status_transition_decision"],
      "approval_transition_decision" => row["approval_transition_decision"],
      "action" => required_operator_action,
      "required_operator_action" => required_operator_action,
      "approval_status" => approval_status(row),
      "reason" => reason(row),
      "operator_action_reason" => reason(row),
      "required_operator_actions" => row["required_operator_actions"],
      "operator_action_reasons" => row["operator_action_reasons"],
      "import_action" => row["import_action"],
      "status_transition" => row["status_transition"],
      "approval_transition" => row["approval_transition"],
      "planned_status" => row["planned_status"],
      "realized_status" => row["realized_status"],
      "planned_status_category" => row["planned_status_category"],
      "realized_status_category" => row["realized_status_category"],
      "planned_approval_status" => row["planned_approval_status"],
      "realized_approval_status" => row["realized_approval_status"],
      "planned_approval_category" => row["planned_approval_category"],
      "realized_approval_category" => row["realized_approval_category"],
      "planned_locked" => row["planned_locked"],
      "realized_locked" => row["realized_locked"],
      "planned_executed" => row["planned_executed"],
      "realized_executed" => row["realized_executed"],
      "planned_protection_decision" =>
        protection_decision_status(row["planned_protection_decision"]),
      "realized_protection_decision" =>
        protection_decision_status(row["realized_protection_decision"]),
      "planned_protection_context" => row["planned_protection_decision"],
      "realized_protection_context" => row["realized_protection_decision"],
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_count" => row["invalid_activity_input_count"],
      "invalid_activity_input_reasons" => row["invalid_activity_input_reasons"],
      "source_planned_activity_count" => summary["planned_activity_count"],
      "source_realized_activity_count" => summary["realized_activity_count"],
      "source_lifecycle_state_review_required_count" => summary["review_required_count"],
      "source_lifecycle_state_operator_action_reason_counts" =>
        summary["operator_action_reason_counts"],
      "source_lifecycle_state_review_timeline_ids_by_operator_action_reason" =>
        summary["review_timeline_ids_by_operator_action_reason"],
      "planned_activity_context" => row["planned_activity_context"],
      "realized_activity_context" => row["realized_activity_context"]
    }
    |> maybe_put_candidate_refresh_activity_state_lifecycle_source(row, source)
    |> Map.put(activity_state_source_field(row), row)
    |> compact_map()
  end

  defp maybe_put_candidate_refresh_activity_state_lifecycle_source(
         review_row,
         row,
         "candidate_refresh." <> _source
       ) do
    Map.put_new(
      review_row,
      "source_timeline_lifecycle_state",
      activity_state_lifecycle_source(row)
    )
  end

  defp maybe_put_candidate_refresh_activity_state_lifecycle_source(review_row, _row, _source),
    do: review_row

  defp activity_state_lifecycle_source(%{} = row) do
    row
    |> Map.put_new("schema_contract", activity_state_source_contract(row))
    |> compact_map()
  end

  defp activity_state_source_contract(%{"schema_contract" => contract}) when is_binary(contract),
    do: contract

  defp activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_state"
       }),
       do: "timeline_activity_state.v1"

  defp activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_status_state"
       }),
       do: "timeline_activity_status_state.v1"

  defp activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_approval_state"
       }),
       do: "timeline_activity_approval_state.v1"

  defp activity_state_source_contract(%{
         "model" => "artifact_only_timeline_activity_lifecycle_state"
       }),
       do: "timeline_activity_lifecycle_state.v1"

  defp activity_state_source_contract(_row), do: nil

  defp activity_state_source_field(%{"schema_contract" => "timeline_activity_state.v1"}),
    do: "source_timeline_activity_state"

  defp activity_state_source_field(%{
         "model" => "artifact_only_timeline_activity_state"
       }),
       do: "source_timeline_activity_state"

  defp activity_state_source_field(_row), do: "source_timeline_lifecycle_state"

  defp approval_status(%{"review_required" => false}), do: "not_required"
  defp approval_status(_row), do: "operator_review_required"

  defp required_operator_action(%{"required_operator_action" => action}) when is_binary(action),
    do: action

  defp required_operator_action(%{"required_operator_actions" => [action | _]})
       when is_binary(action),
       do: action

  defp required_operator_action(%{"review_required" => false}), do: "record_timeline_change"

  defp required_operator_action(%{"approval_transition_decision" => "review"}),
    do: "review_activity_approval"

  defp required_operator_action(%{"status_transition_decision" => "review"}),
    do: "review_activity_transition"

  defp required_operator_action(_row), do: "review_timeline_lifecycle_state"

  defp reason(%{"operator_action_reasons" => [reason | _]}), do: reason
  defp reason(%{"operator_action_reason" => reason}) when is_binary(reason), do: reason
  defp reason(%{"required_operator_action" => action}) when is_binary(action), do: action
  defp reason(_row), do: "timeline_lifecycle_state_requires_review"

  defp protection_decision_status(%{"protection_decision" => decision}) when is_binary(decision),
    do: decision

  defp protection_decision_status(decision) when is_binary(decision), do: decision
  defp protection_decision_status(_decision), do: nil

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

  defp activity_package(state, schema_contract, source, fallback) do
    {rows, source_artifact_id, provenance} =
      activity_state_package_input(state, schema_contract, source, fallback)

    build_package(rows, schema_contract, source_artifact_id, provenance)
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
