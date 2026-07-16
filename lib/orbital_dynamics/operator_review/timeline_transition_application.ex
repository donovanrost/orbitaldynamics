defmodule OrbitalDynamics.OperatorReview.TimelineTransitionApplication do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.TimelineDiff

  @schema_contract "operator_review_package.v1"

  def summary_package(summary, opts) do
    {rows, source_artifact_id, provenance} = summary_package_input(summary, opts)

    build_package(
      rows,
      "timeline_transition_application_summary.v1",
      source_artifact_id,
      provenance
    )
  end

  def report_package(report, opts) do
    {rows, source_artifact_id, provenance} = report_package_input(report, opts)

    build_package(
      rows,
      "timeline_transition_application_report.v1",
      source_artifact_id,
      provenance
    )
  end

  def candidate_refresh_rows(artifact) do
    report_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_transition_application_report",
         get_in(artifact, [
           "accepted_planning_state",
           "source_timeline_transition_application_report"
         ])},
        {"candidate_refresh.accepted_planning_state.timeline_transition_application_report",
         get_in(artifact, ["accepted_planning_state", "timeline_transition_application_report"])},
        {"candidate_refresh.mission_state.source_timeline_transition_application_report",
         get_in(artifact, ["mission_state", "source_timeline_transition_application_report"])},
        {"candidate_refresh.mission_state.timeline_transition_application_report",
         get_in(artifact, ["mission_state", "timeline_transition_application_report"])},
        {"candidate_refresh.source_timeline_transition_application_report",
         artifact["source_timeline_transition_application_report"]},
        {"candidate_refresh.timeline_transition_application_report",
         artifact["timeline_transition_application_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    summary_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_transition_application_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_timeline_transition_application_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.timeline_transition_application_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_transition_application_summary"])},
        {"candidate_refresh.mission_state.source_timeline_transition_application_summary",
         get_in(artifact, ["mission_state", "source_timeline_transition_application_summary"])},
        {"candidate_refresh.mission_state.timeline_transition_application_summary",
         get_in(artifact, ["mission_state", "timeline_transition_application_summary"])},
        {"candidate_refresh.source_timeline_transition_application_summary",
         artifact["source_timeline_transition_application_summary"]},
        {"candidate_refresh.timeline_transition_application_summary",
         artifact["timeline_transition_application_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_summary_rows(summary_or_summaries, source)
      end)

    report_rows ++ summary_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def summary_package_input(summary, opts) do
    summary = stringify_keys(summary || %{})

    summary =
      Map.put_new(summary, "schema_contract", "timeline_transition_application_summary.v1")

    {
      summary_rows(summary, opts),
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_transition_application_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def report_package_input(report, opts) do
    report = stringify_keys(report || %{})

    {
      rows(
        Map.get(report, "applications", []),
        "timeline_transition_application_report.applications",
        approval_policy(opts)
      ),
      Map.get(report, "id") || Map.get(report, "source") ||
        "timeline_transition_application_report",
      Map.get(report, "provenance", %{})
    }
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    rows(
      Map.get(report, "applications", []),
      "#{source}.applications",
      nil
    )
  end

  def source_report_rows(_report, _source), do: []

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
    |> summary_rows([], "#{source}.review_applications")
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
         %{"schema_contract" => "timeline_transition_application_summary.v1"} = summary,
         source
       ) do
    source_summary_rows(summary, source)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "timeline_transition_application_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_transition_application_report",
       artifact["source_timeline_transition_application_report"]},
      {"#{source}.timeline_transition_application_report",
       artifact["timeline_transition_application_report"]},
      {"#{source}.source_timeline_transition_application_summary",
       artifact["source_timeline_transition_application_summary"]},
      {"#{source}.timeline_transition_application_summary",
       artifact["timeline_transition_application_summary"]}
    ]
    |> Enum.flat_map(fn {source_field, report_or_summary} ->
      if String.ends_with?(source_field, "_report") do
        source_report_rows(report_or_summary, source_field)
      else
        source_summary_rows(report_or_summary, source_field)
      end
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def rows(rows, source, approval_policy) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&Map.get(&1, "requires_operator_review", false))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      source_diff =
        row
        |> Map.get("source_timeline_diff", %{})
        |> stringify_keys()
        |> Map.merge(
          Map.take(row, [
            "application_status",
            "selected_activity_source",
            "selected_activity",
            "requires_operator_review",
            "required_operator_action",
            "reason",
            "selected_timeline_integrity_status",
            "selected_timeline_integrity_issue_count",
            "selected_timeline_integrity_issue_types",
            "selected_timeline_integrity_issues",
            "selected_missing_dependency_activity_ids",
            "selected_missing_dependency_timeline_ids",
            "selected_self_dependency_activity_ids",
            "selected_self_dependency_timeline_ids",
            "selected_duplicate_dependency_activity_ids",
            "selected_duplicate_dependency_timeline_ids",
            "selected_duplicate_exclusivity_activity_ids",
            "selected_duplicate_exclusivity_timeline_ids",
            "selected_dependency_cycle_activity_ids",
            "selected_dependency_cycle_timeline_ids",
            "selected_dependency_order_violation_activity_ids",
            "selected_dependency_order_violation_timeline_ids",
            "selected_exclusivity_violation_activity_ids",
            "selected_exclusivity_violation_timeline_ids",
            "selected_exclusivity_violation_group",
            "transition_application_provenance"
          ])
        )

      source_diff
      |> TimelineDiff.review_row(index, source)
      |> Map.put("application_status", row["application_status"])
      |> Map.put("selected_activity_source", row["selected_activity_source"])
      |> Map.put("selected_activity", row["selected_activity"])
      |> Map.put("transition_application_provenance", row["transition_application_provenance"])
      |> Map.put("source_timeline_application", row)
      |> compact_map()
    end)
    |> apply_review_row_policy(
      approval_policy,
      "timeline_transition_application_policy_context"
    )
  end

  def approval_policy(opts), do: option(opts, :approval_policy) || option(opts, "approval_policy")

  def summary_rows(
        summary,
        opts,
        source \\ "timeline_transition_application_summary.review_applications"
      )

  def summary_rows(%{} = summary, opts, source) do
    summary
    |> Map.get("review_applications", [])
    |> rows(
      source,
      approval_policy(opts)
    )
    |> Enum.map(&put_summary_context(&1, summary))
  end

  defp put_summary_context(row, summary) do
    %{
      "source_artifact_type" => summary["source_artifact_type"],
      "source_transition_application_source_activity_count" => summary["source_activity_count"],
      "source_transition_application_replacement_activity_count" =>
        summary["replacement_activity_count"],
      "source_transition_application_count" => summary["application_count"],
      "source_transition_application_selected_activity_count" =>
        summary["selected_activity_count"],
      "source_transition_application_review_required_count" => summary["review_required_count"],
      "source_transition_application_preserved_source_count" => summary["preserved_source_count"],
      "source_transition_application_recorded_replacement_count" =>
        summary["recorded_replacement_count"],
      "source_transition_application_withheld_review_count" => summary["withheld_review_count"],
      "source_transition_application_selected_timeline_integrity_review_count" =>
        summary["selected_timeline_integrity_review_count"],
      "source_transition_application_selected_timeline_integrity_issue_count" =>
        summary["selected_timeline_integrity_issue_count"],
      "source_transition_application_selected_timeline_integrity_issue_types" =>
        summary["selected_timeline_integrity_issue_types"],
      "source_transition_application_status_counts" => summary["application_status_counts"],
      "source_transition_application_decision_counts" => summary["transition_decision_counts"],
      "source_transition_application_required_operator_action_counts" =>
        summary["required_operator_action_counts"],
      "source_transition_application_status_transition_category_counts" =>
        summary["status_transition_category_counts"],
      "source_transition_application_approval_transition_category_counts" =>
        summary["approval_transition_category_counts"],
      "source_transition_application_selected_activity_ids" => summary["selected_activity_ids"],
      "source_transition_application_selected_timeline_ids" => summary["selected_timeline_ids"],
      "source_transition_application_review_activity_ids" => summary["review_activity_ids"],
      "source_transition_application_review_timeline_ids" => summary["review_timeline_ids"],
      "source_transition_application_review_timeline_ids_by_required_operator_action" =>
        summary["review_timeline_ids_by_required_operator_action"],
      "source_transition_application_review_timeline_ids_by_status_transition_category" =>
        summary["review_timeline_ids_by_status_transition_category"],
      "source_transition_application_review_timeline_ids_by_approval_transition_category" =>
        summary["review_timeline_ids_by_approval_transition_category"],
      "source_transition_application_preserved_source_timeline_ids" =>
        summary["preserved_source_timeline_ids"],
      "source_transition_application_recorded_replacement_timeline_ids" =>
        summary["recorded_replacement_timeline_ids"],
      "source_transition_application_withheld_review_timeline_ids" =>
        summary["withheld_review_timeline_ids"],
      "source_timeline_transition_application_summary" => summary
    }
    |> compact_map()
    |> then(&Map.merge(row, &1))
  end

  defp apply_review_row_policy([], _approval_policy, _context_id), do: []
  defp apply_review_row_policy(rows, nil, _context_id), do: rows

  defp apply_review_row_policy(rows, approval_policy, context_id) do
    {_status, enriched_rows, rule_matches, policy_decision} =
      OrbitalDynamics.Policy.decide(
        rows,
        [],
        %{"id" => context_id, "events" => []},
        %{},
        approval_policy
      )

    if rule_matches == [] do
      rows
    else
      Enum.map(enriched_rows, fn row ->
        if Map.has_key?(row, "approval_rule_matches") do
          Map.put(row, "source_policy_decision", policy_decision)
        else
          row
        end
      end)
    end
  end

  defp option(opts, key) when is_list(opts) do
    case List.keyfind(opts, key, 0) do
      {_key, value} -> value
      nil -> nil
    end
  end

  defp option(%{} = opts, key), do: Map.get(opts, key)
  defp option(_opts, _key), do: nil

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
