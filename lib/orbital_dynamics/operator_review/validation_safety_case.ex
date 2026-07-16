defmodule OrbitalDynamics.OperatorReview.ValidationSafetyCase do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(summary) do
    {rows, source_artifact_id, provenance} = package_input(summary)

    build_package(rows, "validation_safety_case_summary.v1", source_artifact_id, provenance)
  end

  def package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      rows(summary),
      Map.get(summary, "summary_id") || summary_id(summary),
      Map.get(summary, "provenance", %{})
    }
  end

  def rows(summary, source \\ "validation_safety_case_summary.evidence") do
    summary = stringify_keys(summary)

    summary
    |> Map.get("evidence", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&reviewable_evidence?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {evidence, index} ->
      status = evidence["status"] || "review_required"

      evidence_ref =
        evidence["evidence_ref"] || "#{evidence["schema_contract"] || "evidence"}:#{index}"

      action = action(status)

      %{
        "id" =>
          review_id([
            "validation_safety_case_review",
            stable_id_fragment(source),
            stable_id_fragment(evidence_ref),
            index
          ]),
        "review_type" => "validation_safety_case_review",
        "source" => source,
        "subject_id" => stable_id_fragment(evidence_ref),
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => approval_status(status),
        "reason" => reason(summary, evidence, status, evidence_ref),
        "validation_safety_case_summary_id" => summary["summary_id"],
        "validation_safety_case_status" => summary["status"],
        "validation_safety_case_evidence_status" => status,
        "validation_safety_case_evidence_ref" => evidence_ref,
        "validation_safety_case_input_contract" => evidence["schema_contract"],
        "validation_safety_case_blocked_evidence_count" => summary["blocked_evidence_count"],
        "validation_safety_case_review_required_evidence_count" =>
          summary["review_required_evidence_count"],
        "validation_safety_case_schema_error_count" => summary["schema_error_count"],
        "validation_safety_case_schema_warning_count" => summary["schema_warning_count"],
        "validation_safety_case_model_blocked_count" => summary["model_blocked_count"],
        "validation_safety_case_model_review_required_count" =>
          summary["model_review_required_count"],
        "source_validation_safety_case_evidence" => evidence,
        "source_validation_safety_case_summary" => context(summary)
      }
      |> compact_map()
    end)
  end

  def summary_id(summary) do
    review_id([
      "validation_safety_case_summary",
      summary["case_id"],
      summary["status"],
      summary["evidence_count"]
    ])
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_validation_safety_case_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_validation_safety_case_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.validation_safety_case_summary",
         get_in(artifact, ["accepted_planning_state", "validation_safety_case_summary"])},
        {"candidate_refresh.mission_state.source_validation_safety_case_summary",
         get_in(artifact, ["mission_state", "source_validation_safety_case_summary"])},
        {"candidate_refresh.mission_state.validation_safety_case_summary",
         get_in(artifact, ["mission_state", "validation_safety_case_summary"])},
        {"candidate_refresh.source_validation_safety_case_summary",
         artifact["source_validation_safety_case_summary"]},
        {"candidate_refresh.validation_safety_case_summary",
         artifact["validation_safety_case_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_summary_rows(%{} = summary, source), do: rows(summary, "#{source}.evidence")
  defp source_summary_rows(_summary, _source), do: []

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
         %{"schema_contract" => "validation_safety_case_summary.v1"} = summary,
         source
       ) do
    source_summary_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_validation_safety_case_summary",
       artifact["source_validation_safety_case_summary"]},
      {"#{source}.validation_safety_case_summary", artifact["validation_safety_case_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_summary_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp reviewable_evidence?(%{} = evidence),
    do: evidence["status"] in ["blocked", "review_required"]

  defp reviewable_evidence?(_evidence), do: false

  defp action("blocked"), do: "review_blocked_validation_safety_case"
  defp action(_status), do: "review_validation_safety_case"

  defp approval_status("blocked"), do: "blocked_by_policy"
  defp approval_status(_status), do: "operator_review_required"

  defp reason(summary, evidence, status, evidence_ref) do
    case_id = summary["case_id"] || summary["summary_id"] || "validation safety case"
    contract = evidence["schema_contract"] || "evidence"

    "#{case_id} has #{status} #{contract} evidence at #{evidence_ref}"
  end

  defp context(summary) do
    Map.take(summary, [
      "schema_contract",
      "schema_version",
      "model",
      "source",
      "summary_id",
      "case_id",
      "status",
      "evidence_count",
      "input_contracts",
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "blocked_evidence_count",
      "review_required_evidence_count",
      "accepted_evidence_count",
      "model_accepted_count",
      "model_review_required_count",
      "model_blocked_count",
      "unknown_model_count",
      "readiness_review_required_count",
      "readiness_blocked_count",
      "ready_for_import_count",
      "quality_gate_review_count",
      "quality_gate_blocked_count",
      "schema_error_count",
      "schema_warning_count",
      "schema_validation_report_count",
      "schema_validation_failed_report_count",
      "fixture_passed_count",
      "fixture_failed_count",
      "assumptions",
      "model_limits"
    ])
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

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
