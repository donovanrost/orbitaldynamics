defmodule OrbitalDynamics.OperatorReview.OperationalReadiness do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    rows
    |> build_package("operational_readiness_report.v1", source_artifact_id, provenance)
    |> put_report_summary(report)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(report),
      Map.get(report, "report_id") || "operational_readiness_report",
      Map.get(report, "provenance", %{})
    }
  end

  def rows(report, source \\ "operational_readiness_report") do
    classification = report["import_classification"] || "review_only"
    action = operational_readiness_action(classification)

    summary_row =
      %{
        "id" => review_id(["operational_readiness", report["report_id"] || classification]),
        "review_type" => "operational_readiness_review",
        "source" => source,
        "subject_id" =>
          report["report_id"] || report["source_artifact_id"] || "operational_readiness",
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => operational_readiness_approval_status(classification),
        "cadence_import_status" => operational_readiness_cadence_import_status(classification),
        "reason" => operational_readiness_reason(report, classification),
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => report["readiness_level"],
        "import_classification" => classification,
        "operational_readiness_status" => report["status"],
        "gate_count" => report["gate_count"],
        "passed_gate_count" => report["passed_gate_count"],
        "review_gate_count" => report["review_gate_count"],
        "analysis_gate_count" => report["analysis_gate_count"],
        "blocked_gate_count" => report["blocked_gate_count"],
        "gates" => report["gates"],
        "evidence" => report["evidence"],
        "source_operational_readiness_report" => operational_readiness_report_context(report)
      }
      |> Map.merge(operational_readiness_report_resource_context(report))
      |> compact_map()

    [summary_row | operational_readiness_gate_rows(report, source)]
  end

  def put_report_summary(package, report) do
    report = stringify_keys(report || %{})

    Map.merge(package, operational_readiness_report_summary_context(report))
  end

  defp operational_readiness_report_summary_context(report) do
    report
    |> Map.take([
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count"
    ])
    |> Map.put("source_readiness_report_id", report["report_id"])
    |> compact_map()
  end

  defp operational_readiness_gate_rows(report, source) do
    report
    |> Map.get("gates", [])
    |> Enum.filter(&operational_readiness_reviewable_gate?/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn gate ->
      gate_id = gate["id"] || "operational_gate"
      gate_status = gate["status"] || "review_required"
      classification = gate["classification"] || "review_only"
      action = operational_readiness_gate_action(gate)

      %{
        "id" =>
          review_id([
            "operational_readiness_gate",
            report["report_id"] || report["source_artifact_id"] || "operational_readiness",
            gate_id
          ]),
        "review_type" => "operational_readiness_review",
        "source" => "#{source}.gates",
        "subject_id" =>
          [
            report["report_id"] || report["source_artifact_id"] || "operational_readiness",
            gate_id
          ]
          |> Enum.map(&encode_value/1)
          |> Enum.join(":"),
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => operational_readiness_gate_approval_status(gate),
        "cadence_import_status" => operational_readiness_cadence_import_status(classification),
        "reason" => gate["reason"],
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => readiness_level(classification),
        "import_classification" => classification,
        "operational_readiness_status" => gate_status,
        "readiness_gate_id" => gate_id,
        "readiness_gate_status" => gate_status,
        "readiness_gate_classification" => classification,
        "readiness_gate_reason" => gate["reason"],
        "analysis_mode" => gate["analysis_mode"],
        "analysis_mode_source" => gate["analysis_mode_source"],
        "source_operational_readiness_gate" => gate,
        "source_operational_readiness_report" => operational_readiness_report_context(report)
      }
      |> Map.merge(operational_readiness_gate_context(gate))
      |> compact_map()
    end)
  end

  defp operational_readiness_gate_context(%{"id" => "resource_availability"} = gate) do
    reason_counts = Map.get(gate, "resource_availability_reason_counts") || %{}

    %{
      "resource_availability_pressure_count" => gate["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" =>
        gate["resource_availability_reason_ids"] ||
          operational_readiness_count_keys(reason_counts),
      "station_availability_reason_ids" =>
        gate["station_availability_reason_ids"] ||
          operational_readiness_station_reason_ids(reason_counts),
      "station_availability_reason_counts" =>
        gate["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        gate["unavailable_resource_reason_ids"] ||
          operational_readiness_unavailable_reason_ids(reason_counts),
      "resource_blocking_dimension_counts" => gate["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        gate["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        gate["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => gate["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => gate["resource_trust_boundary_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "cadence_import"} = gate) do
    %{
      "ready_for_import_count" => gate["ready_for_import_count"],
      "manifest_review_required_count" => gate["manifest_review_required_count"],
      "blocked_import_count" => gate["blocked_import_count"],
      "missing_import_count" => gate["missing_import_count"],
      "invalid_cadence_import_count" => gate["invalid_cadence_import_count"],
      "current_freshness_count" => gate["current_freshness_count"],
      "stale_freshness_count" => gate["stale_freshness_count"],
      "unknown_freshness_count" => gate["unknown_freshness_count"],
      "freshness_status_counts" => gate["freshness_status_counts"],
      "schema_validation_pass_count" => gate["schema_validation_pass_count"],
      "schema_validation_fail_count" => gate["schema_validation_fail_count"],
      "schema_validation_error_count" => gate["schema_validation_error_count"],
      "schema_validation_warning_count" => gate["schema_validation_warning_count"],
      "schema_validation_remediation_count" => gate["schema_validation_remediation_count"],
      "schema_validation_status_counts" => gate["schema_validation_status_counts"],
      "import_status_counts" => gate["import_status_counts"],
      "cadence_import_status_counts" => gate["cadence_import_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "adapter_boundary"} = gate) do
    %{
      "adapter_context_count" => gate["adapter_context_count"],
      "adapter_trust_boundary_declared_count" => gate["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" => gate["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" => gate["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" => gate["adapter_boundary_status_counts"]
    }
  end

  defp operational_readiness_gate_context(%{"id" => "operator_training"} = gate) do
    %{
      "operator_training_requirement_count" => gate["operator_training_requirement_count"],
      "operator_training_requirement_counts" => gate["operator_training_requirement_counts"],
      "required_operator_roles" => gate["required_operator_roles"],
      "required_training_ids" => gate["required_training_ids"],
      "required_certification_ids" => gate["required_certification_ids"],
      "required_qualification_ids" => gate["required_qualification_ids"]
    }
  end

  defp operational_readiness_gate_context(_gate), do: %{}

  defp operational_readiness_report_resource_context(report) do
    evidence = Map.get(report, "evidence") || %{}

    reason_counts =
      report["resource_availability_reason_counts"] ||
        evidence["resource_availability_reason_counts"] ||
        %{}

    %{
      "resource_availability_pressure_count" =>
        report["resource_availability_pressure_count"] ||
          evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => non_empty_map(reason_counts),
      "resource_availability_reason_ids" =>
        report["resource_availability_reason_ids"] ||
          evidence["resource_availability_reason_ids"] ||
          operational_readiness_non_empty_list(operational_readiness_count_keys(reason_counts)),
      "station_availability_reason_ids" =>
        report["station_availability_reason_ids"] ||
          evidence["station_availability_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_station_reason_ids(reason_counts)
          ),
      "station_availability_reason_counts" =>
        report["station_availability_reason_counts"] ||
          evidence["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        report["unavailable_resource_reason_ids"] ||
          evidence["unavailable_resource_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_unavailable_reason_ids(reason_counts)
          ),
      "resource_blocking_dimension_counts" =>
        report["resource_blocking_dimension_counts"] ||
          evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        report["resource_blocked_contact_ids_by_blocking_dimension"] ||
          evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        report["resource_blocked_contact_ids_by_spacecraft_id"] ||
          evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" =>
        report["resource_source_quality_counts"] || evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" =>
        report["resource_trust_boundary_status_counts"] ||
          evidence["resource_trust_boundary_status_counts"]
    }
  end

  defp operational_readiness_non_empty_list([_ | _] = values), do: values
  defp operational_readiness_non_empty_list(_values), do: nil

  defp operational_readiness_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.sort()
  end

  defp operational_readiness_count_keys(_counts), do: nil

  defp operational_readiness_unavailable_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in operational_readiness_unavailable_reasons()))
    |> Enum.sort()
  end

  defp operational_readiness_unavailable_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in operational_readiness_station_reasons()))
    |> Enum.sort()
  end

  defp operational_readiness_station_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_counts(counts) when is_map(counts) do
    counts
    |> Enum.filter(fn {reason, count} ->
      reason in operational_readiness_station_reasons() and is_integer(count) and count > 0
    end)
    |> Map.new()
  end

  defp operational_readiness_station_reason_counts(_counts), do: %{}

  defp operational_readiness_unavailable_reasons do
    ~w(
      antenna_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp operational_readiness_station_reasons do
    ~w(
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
    )
  end

  defp operational_readiness_reviewable_gate?(%{} = gate),
    do: (gate["status"] || gate[:status]) not in [nil, "passed"]

  defp operational_readiness_reviewable_gate?(_gate), do: false

  defp operational_readiness_gate_action(%{"classification" => classification}),
    do: operational_readiness_action(classification)

  defp operational_readiness_gate_action(_gate), do: operational_readiness_action("review_only")

  defp operational_readiness_gate_approval_status(%{"classification" => classification}),
    do: operational_readiness_approval_status(classification)

  defp operational_readiness_gate_approval_status(_gate),
    do: operational_readiness_approval_status("review_only")

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_operational_readiness_report",
         artifact["source_operational_readiness_report"]},
        {"candidate_refresh.operational_readiness_report",
         artifact["operational_readiness_report"]},
        {"candidate_refresh.source_operational_import_eligibility_summary",
         artifact["source_operational_import_eligibility_summary"]},
        {"candidate_refresh.operational_import_eligibility_summary",
         artifact["operational_import_eligibility_summary"]},
        {"candidate_refresh.source_operational_readiness_gate_summary",
         artifact["source_operational_readiness_gate_summary"]},
        {"candidate_refresh.operational_readiness_gate_summary",
         artifact["operational_readiness_gate_summary"]},
        {"candidate_refresh.source_operational_execution_boundary_summary",
         artifact["source_operational_execution_boundary_summary"]},
        {"candidate_refresh.operational_execution_boundary_summary",
         artifact["operational_execution_boundary_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++
      candidate_refresh_result_artifact_rows(artifact) ++
      candidate_refresh_summary_rows(artifact)
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> operational_readiness_report_from_source()
    |> rows(source)
  end

  def source_report_rows(_report, _source), do: []

  defp operational_readiness_report_from_source(%{} = report) do
    cond do
      operational_import_eligibility_summary?(report) ->
        operational_readiness_report_from_summary(report)

      operational_readiness_gate_summary?(report) ->
        operational_readiness_report_from_summary(report)

      operational_execution_boundary_summary?(report) ->
        operational_readiness_report_from_summary(report)

      true ->
        report
    end
  end

  defp operational_readiness_report_from_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
  end

  defp operational_import_eligibility_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_import_eligibility_summary" or
         summary["schema_contract"] == "operational_import_eligibility_summary.v1")
  end

  defp operational_readiness_gate_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_operational_readiness_gate_summary" or
         summary["schema_contract"] == "operational_readiness_gate_summary.v1")
  end

  defp operational_execution_boundary_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["gate_count"]) and
      (summary["model"] == "artifact_only_operational_execution_boundary_summary" or
         summary["schema_contract"] == "operational_execution_boundary_summary.v1")
  end

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
         %{"schema_contract" => "operational_readiness_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_operational_readiness_report",
       artifact["source_operational_readiness_report"]},
      {"#{source}.operational_readiness_report", artifact["operational_readiness_report"]},
      {"#{source}.source_operational_import_eligibility_summary",
       artifact["source_operational_import_eligibility_summary"]},
      {"#{source}.operational_import_eligibility_summary",
       artifact["operational_import_eligibility_summary"]},
      {"#{source}.source_operational_readiness_gate_summary",
       artifact["source_operational_readiness_gate_summary"]},
      {"#{source}.operational_readiness_gate_summary",
       artifact["operational_readiness_gate_summary"]},
      {"#{source}.source_operational_execution_boundary_summary",
       artifact["source_operational_execution_boundary_summary"]},
      {"#{source}.operational_execution_boundary_summary",
       artifact["operational_execution_boundary_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp candidate_refresh_summary_rows(artifact) do
    summary = get_in(artifact, ["provenance", "source_reports", "operational_readiness_report"])

    case summary do
      %{} = summary when map_size(summary) > 0 ->
        summary = stringify_keys(summary)
        classification = operational_readiness_summary_classification(summary)
        action = operational_readiness_action(classification)
        report_id = "candidate_refresh.operational_readiness_source_reports"
        evidence = operational_readiness_summary_evidence(summary)
        resource_context = operational_readiness_summary_resource_context(summary)

        [
          %{
            "id" => review_id(["operational_readiness", report_id]),
            "review_type" => "operational_readiness_review",
            "source" =>
              "candidate_refresh.provenance.source_reports.operational_readiness_report",
            "subject_id" => report_id,
            "action" => action,
            "required_operator_action" => action,
            "approval_status" => operational_readiness_approval_status(classification),
            "cadence_import_status" =>
              operational_readiness_cadence_import_status(classification),
            "reason" =>
              "candidate refresh included #{summary["count"] || 0} operational readiness source report(s) classified #{classification}",
            "source_artifact_type" => "operational_readiness_report.v1",
            "source_artifact_id" => report_id,
            "readiness_level" => operational_readiness_summary_readiness_level(summary),
            "import_classification" => classification,
            "operational_readiness_status" => operational_readiness_summary_status(summary),
            "gate_count" => summary["gate_count"],
            "passed_gate_count" => summary["passed_gate_count"],
            "review_gate_count" => summary["review_gate_count"],
            "analysis_gate_count" => summary["analysis_gate_count"],
            "blocked_gate_count" => summary["blocked_gate_count"],
            "evidence" => evidence,
            "source_operational_readiness_report" =>
              Map.merge(summary, %{
                "schema_contract" => "operational_readiness_report.v1",
                "summary_source" =>
                  "candidate_refresh.provenance.source_reports.operational_readiness_report"
              })
          }
          |> Map.merge(resource_context)
          |> compact_map()
        ]

      _summary ->
        []
    end
  end

  defp operational_readiness_summary_classification(summary) do
    counts = summary["import_classification_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) or positive_count?(summary["blocked_gate_count"]) ->
        "blocked"

      positive_count?(counts["review_only"]) or positive_count?(summary["review_gate_count"]) ->
        "review_only"

      positive_count?(counts["analysis_only"]) or positive_count?(summary["analysis_gate_count"]) ->
        "analysis_only"

      positive_count?(counts["importable"]) ->
        "importable"

      true ->
        "review_only"
    end
  end

  defp operational_readiness_summary_readiness_level(summary) do
    counts = summary["readiness_level_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) -> "blocked"
      positive_count?(counts["operator_review"]) -> "operator_review"
      positive_count?(counts["analysis_only"]) -> "analysis_only"
      positive_count?(counts["import_eligible"]) -> "import_eligible"
      true -> readiness_level(operational_readiness_summary_classification(summary))
    end
  end

  defp operational_readiness_summary_status(summary) do
    counts = summary["status_counts"] || %{}

    cond do
      positive_count?(counts["blocked"]) -> "blocked"
      positive_count?(counts["review_required"]) -> "review_required"
      positive_count?(counts["analysis_only"]) -> "analysis_only"
      positive_count?(counts["passed"]) -> "passed"
      true -> nil
    end
  end

  defp operational_readiness_summary_evidence(summary) do
    [
      "ready_for_import_count",
      "review_required_count",
      "schema_validation_fail_count",
      "stale_freshness_count",
      "source_model_limit_count",
      "resource_availability_pressure_count",
      "resource_availability_reason_counts",
      "resource_availability_reason_ids",
      "station_availability_reason_ids",
      "station_availability_reason_counts",
      "unavailable_resource_reason_ids",
      "resource_blocking_dimension_counts"
    ]
    |> operational_readiness_summary_keys(summary)
    |> non_empty_map()
  end

  defp operational_readiness_summary_resource_context(summary) do
    [
      "resource_availability_pressure_count",
      "resource_availability_reason_counts",
      "resource_availability_reason_ids",
      "station_availability_reason_ids",
      "station_availability_reason_counts",
      "unavailable_resource_reason_ids",
      "resource_blocking_dimension_counts"
    ]
    |> operational_readiness_summary_keys(summary)
  end

  defp operational_readiness_summary_keys(keys, summary) do
    keys
    |> Enum.reduce(%{}, fn key, evidence ->
      case summary[key] do
        value when value in [nil, 0] -> evidence
        value -> Map.put(evidence, key, value)
      end
    end)
  end

  defp operational_readiness_action("importable"), do: "record_operational_readiness_importable"

  defp operational_readiness_action("analysis_only"),
    do: "record_operational_readiness_analysis_only"

  defp operational_readiness_action("blocked"), do: "review_blocked_operational_readiness"
  defp operational_readiness_action(_classification), do: "review_operational_readiness"

  defp operational_readiness_approval_status("importable"), do: "auto_approvable"
  defp operational_readiness_approval_status("analysis_only"), do: "not_required"
  defp operational_readiness_approval_status("blocked"), do: "blocked_by_policy"
  defp operational_readiness_approval_status(_classification), do: "operator_review_required"

  defp operational_readiness_cadence_import_status("analysis_only"), do: "not_applicable"
  defp operational_readiness_cadence_import_status(_classification), do: "present"

  defp readiness_level("importable"), do: "import_eligible"
  defp readiness_level("review_only"), do: "operator_review"
  defp readiness_level("analysis_only"), do: "analysis_only"
  defp readiness_level("blocked"), do: "blocked"
  defp readiness_level(_classification), do: "operator_review"

  defp positive_count?(value) when is_integer(value), do: value > 0
  defp positive_count?(value) when is_float(value), do: value > 0.0
  defp positive_count?(_value), do: false

  defp operational_readiness_reason(report, classification) do
    source_type = report["source_artifact_type"] || "artifact"
    source_id = report["source_artifact_id"] || "unknown"

    "operational readiness classified #{source_type} #{source_id} as #{classification}"
  end

  defp operational_readiness_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "report_id",
      "source_summary_model",
      "source_summary_schema_contract",
      "source_artifact_type",
      "source_artifact_id",
      "readiness_level",
      "import_classification",
      "import_eligible",
      "status",
      "handoff_only",
      "execution_allowed",
      "cadence_write_allowed",
      "operator_authority_granted",
      "execution_boundary",
      "analysis_mode",
      "analysis_mode_source",
      "operational_mode_gate",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gate_status_counts",
      "gate_classification_counts",
      "gate_ids_by_status",
      "gate_ids_by_classification",
      "passed_gate_ids",
      "review_required_gate_ids",
      "analysis_only_gate_ids",
      "blocked_gate_ids",
      "non_passed_gate_count",
      "non_passed_gate_ids",
      "non_passed_gates",
      "gates",
      "evidence",
      "model_limits",
      "assumptions"
    ])
  end

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

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil
end
