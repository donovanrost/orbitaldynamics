defmodule OrbitalDynamics.OperationalReadiness do
  @moduledoc """
  Classifies artifact-only operational readiness from review/import evidence.

  The report is a gate summary over existing operator-review packages and
  Cadence-import manifests. It does not approve work, mutate schedules, or call
  external import APIs.
  """

  alias OrbitalDynamics.CadenceImport

  @schema_contract "operational_readiness_report.v1"
  @import_eligibility_summary_schema_contract "operational_import_eligibility_summary.v1"
  @gate_summary_schema_contract "operational_readiness_gate_summary.v1"
  @execution_boundary_summary_schema_contract "operational_execution_boundary_summary.v1"
  @quality_gate_schema_contract "quality_gate_report.v1"
  @quality_gate_summary_schema_contract "operational_quality_gate_summary.v1"
  @quality_gate_unavailable_resource_summary_schema_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_gate_operator_training_summary_schema_contract "operational_quality_gate_operator_training_summary.v1"
  @quality_gate_schema_validation_summary_schema_contract "operational_quality_gate_schema_validation_summary.v1"
  @quality_gate_import_readiness_summary_schema_contract "operational_quality_gate_import_readiness_summary.v1"
  @schema_version 1
  @import_classifications ~w(importable review_only analysis_only blocked)
  @readiness_levels ~w(import_eligible operator_review analysis_only blocked)
  @gate_statuses ~w(passed review_required analysis_only blocked)
  @analysis_modes ~w(analysis_only simulation rehearsal trade_study training not_for_execution)
  @analysis_mode_aliases %{
    "analysis" => "analysis_only",
    "analysis_mode" => "analysis_only",
    "analytical" => "analysis_only",
    "dry_run" => "simulation",
    "exercise" => "rehearsal",
    "no_execute" => "not_for_execution",
    "no_execution" => "not_for_execution",
    "not_for_ops" => "not_for_execution",
    "ops_rehearsal" => "rehearsal",
    "sim" => "simulation",
    "trade" => "trade_study",
    "tradeoff" => "trade_study"
  }

  @doc """
  Declares the operational-readiness report model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_operational_readiness_classifier,
      validation_level: :artifact_contract,
      import_eligibility_summary_artifact_contract: @import_eligibility_summary_schema_contract,
      gate_summary_artifact_contract: @gate_summary_schema_contract,
      execution_boundary_summary_artifact_contract: @execution_boundary_summary_schema_contract,
      quality_gate_summary_artifact_contract: @quality_gate_summary_schema_contract,
      quality_gate_unavailable_resource_summary_artifact_contract:
        @quality_gate_unavailable_resource_summary_schema_contract,
      quality_gate_operator_training_summary_artifact_contract:
        @quality_gate_operator_training_summary_schema_contract,
      quality_gate_schema_validation_summary_artifact_contract:
        @quality_gate_schema_validation_summary_schema_contract,
      quality_gate_import_readiness_summary_artifact_contract:
        @quality_gate_import_readiness_summary_schema_contract,
      import_classifications: @import_classifications,
      readiness_levels: @readiness_levels,
      gate_statuses: @gate_statuses,
      analysis_modes: @analysis_modes,
      analysis_mode_aliases: @analysis_mode_aliases,
      gates: [
        "source_contract",
        "operational_mode",
        "adapter_boundary",
        "mission_policy",
        "operator_training",
        "resource_availability",
        "operator_review",
        "cadence_import"
      ],
      readiness_helpers: [
        :report,
        :import_eligibility,
        :gate_summary,
        :execution_boundary_summary,
        :quality_gate_report,
        :quality_gate_summary,
        :quality_gate_unavailable_resource_summary,
        :quality_gate_operator_training_summary,
        :quality_gate_schema_validation_summary,
        :quality_gate_import_readiness_summary
      ],
      summary_semantics: [
        :import_eligibility_summary,
        :readiness_summary_row_derived_gate_counts,
        :gate_status_routing_id_sets,
        :gate_classification_routing_id_sets,
        :quality_gate_report_routing_id_sets,
        :quality_gate_report_row_derived_classification,
        :quality_gate_report_execution_boundary,
        :quality_gate_summary,
        :quality_gate_summary_row_derived_counts,
        :quality_gate_resource_availability_row_context,
        :quality_gate_unavailable_resource_summary,
        :quality_gate_unavailable_resource_routing_id_sets,
        :quality_gate_operator_training_summary,
        :quality_gate_operator_training_routing_id_sets,
        :quality_gate_schema_validation_summary,
        :quality_gate_schema_validation_routing_id_sets,
        :quality_gate_import_readiness_summary,
        :quality_gate_import_readiness_routing_id_sets,
        :quality_gate_cadence_import_row_context,
        :resource_availability_quality_gate,
        :execution_boundary_summary
      ],
      readiness_evidence_semantics: [
        :readiness_review_and_import_row_counts,
        :readiness_review_status_count_maps,
        :readiness_import_status_count_maps,
        :readiness_freshness_status_count_maps,
        :readiness_schema_validation_status_and_issue_counts,
        :readiness_source_model_and_limit_count_maps,
        :readiness_mission_policy_classification_count_maps,
        :readiness_operator_training_requirement_count_maps,
        :readiness_adapter_boundary_status_count_maps,
        :readiness_adapter_boundary_untrusted_count_maps,
        :readiness_resource_availability_reason_count_maps,
        :readiness_resource_availability_reason_ids,
        :readiness_unavailable_resource_reason_ids,
        :readiness_station_availability_reason_count_maps
      ],
      quality_gate_row_semantics: [
        :quality_gate_status_and_classification_counts,
        :quality_gate_status_and_classification_id_sets,
        :quality_gate_adapter_boundary_status_counts,
        :quality_gate_operator_training_requirement_context,
        :quality_gate_resource_availability_reason_ids,
        :quality_gate_station_availability_reason_ids,
        :quality_gate_unavailable_resource_reason_ids,
        :quality_gate_resource_blocking_dimension_counts,
        :quality_gate_resource_blocked_contact_id_maps,
        :quality_gate_cadence_import_status_count_maps,
        :quality_gate_freshness_status_count_maps,
        :quality_gate_schema_validation_status_and_issue_counts
      ],
      public_facades: [
        :operational_readiness_report,
        :operational_import_eligibility,
        :operational_readiness_gate_summary,
        :operational_execution_boundary_summary,
        :operational_quality_gate_report,
        :operational_quality_gate_summary,
        :operational_quality_gate_unavailable_resource_summary,
        :operational_quality_gate_operator_training_summary,
        :operational_quality_gate_schema_validation_summary,
        :operational_quality_gate_import_readiness_summary
      ],
      quality_gate_contract: @quality_gate_schema_contract,
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      handoff_review_type: "operational_readiness_review",
      handoff_import_action: "review_operational_readiness",
      known_limits: [
        :artifact_only,
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_execute_commands,
        :uses_declared_review_and_import_evidence
      ]
    }
  end

  @doc """
  Builds an `operational_readiness_report.v1` from an artifact, review package,
  or Cadence import manifest.
  """
  def report(artifact, opts \\ [])

  def report(%{"schema_contract" => @schema_contract} = report, _opts), do: report

  def report(%{schema_contract: @schema_contract} = report, _opts), do: stringify_keys(report)

  def report(%{} = artifact, opts) when is_list(opts) do
    artifact = stringify_keys(artifact)
    review_package = review_package_for(artifact)
    import_manifest = import_manifest_for(artifact, review_package)

    build_report(artifact, review_package, import_manifest, opts)
  end

  def report(_artifact, _opts) do
    raise ArgumentError, "operational readiness artifact must be a map"
  end

  @doc """
  Builds a compact import-eligibility summary from readiness evidence.

  This helper derives its decision from `report/2` and returns only the
  classification, gate counts, non-passed gates, and boundary assumptions. It
  does not write to Cadence, approve operator actions, or execute commands.
  """
  def import_eligibility(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> import_eligibility_summary()
  end

  @doc """
  Builds a compact gate-routing summary from readiness evidence.

  This helper keeps the full readiness gates visible while grouping gate IDs by
  status and classification. It does not write to Cadence, approve operator
  actions, or execute commands.
  """
  def gate_summary(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> gate_summary_from_report()
  end

  @doc """
  Builds a compact execution-boundary summary from readiness evidence.

  This helper exposes whether a readiness result is import eligible while
  keeping command execution, Cadence writes, and operator authority explicitly
  out of scope. It does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def execution_boundary_summary(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> execution_boundary_summary_from_report()
  end

  @doc """
  Builds a standalone quality-gate report from operational-readiness evidence.

  The report is a deterministic, row-oriented projection of readiness gates for
  adapters that need machine-readable gate routing without reopening the full
  readiness report. It does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def quality_gate_report(artifact, opts \\ [])

  def quality_gate_report(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_report
  end

  def quality_gate_report(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_report(opts)
  end

  def quality_gate_report(artifact, opts) do
    artifact
    |> report(opts)
    |> quality_gate_report_from_readiness()
  end

  @doc """
  Builds a compact row-derived summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes gate status/classification routing only; it
  does not write to Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_summary(artifact, opts \\ [])

  def quality_gate_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_summary_from_report(quality_gate_report)
  end

  def quality_gate_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_summary(opts)
  end

  def quality_gate_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_summary_from_report()
  end

  @doc """
  Builds a compact unavailable-resource routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It only summarizes artifact rows for review/import
  routing; it does not write to Cadence, approve operator actions, or execute
  commands.
  """
  def quality_gate_unavailable_resource_summary(artifact, opts \\ [])

  def quality_gate_unavailable_resource_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_unavailable_resource_summary_from_report(quality_gate_report)
  end

  def quality_gate_unavailable_resource_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_unavailable_resource_summary(opts)
  end

  def quality_gate_unavailable_resource_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_unavailable_resource_summary_from_report()
  end

  @doc """
  Builds a compact operator-training routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing operator-training quality-gate
  role, training, certification, and qualification fields for review/import
  routing only; it does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def quality_gate_operator_training_summary(artifact, opts \\ [])

  def quality_gate_operator_training_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_operator_training_summary_from_report(quality_gate_report)
  end

  def quality_gate_operator_training_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_operator_training_summary(opts)
  end

  def quality_gate_operator_training_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_operator_training_summary_from_report()
  end

  @doc """
  Builds a compact schema-validation routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing Cadence-import quality-gate
  schema-validation fields for review/import routing only; it does not write to
  Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_schema_validation_summary(artifact, opts \\ [])

  def quality_gate_schema_validation_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_schema_validation_summary_from_report(quality_gate_report)
  end

  def quality_gate_schema_validation_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_schema_validation_summary(opts)
  end

  def quality_gate_schema_validation_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_schema_validation_summary_from_report()
  end

  @doc """
  Builds a compact import-readiness routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing Cadence-import quality-gate
  freshness and import-status fields for review/import routing only; it does not
  write to Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_import_readiness_summary(artifact, opts \\ [])

  def quality_gate_import_readiness_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_import_readiness_summary_from_report(quality_gate_report)
  end

  def quality_gate_import_readiness_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_import_readiness_summary(opts)
  end

  def quality_gate_import_readiness_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_import_readiness_summary_from_report()
  end

  defp import_eligibility_summary(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    gate_counts = summary_gate_counts(gates)

    non_passed_gates =
      gates
      |> Enum.reject(&(&1["status"] == "passed"))

    %{
      "schema_contract" => @import_eligibility_summary_schema_contract,
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => report["import_classification"] == "importable",
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gates" => non_passed_gates,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ]
    }
  end

  defp gate_summary_from_report(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    non_passed_gates = Enum.reject(gates, &(&1["status"] == "passed"))
    gate_counts = summary_gate_counts(gates)

    %{
      "schema_contract" => @gate_summary_schema_contract,
      "model" => "artifact_only_operational_readiness_gate_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "gate_status_counts" => gate_summary_counts(gates, "status"),
      "gate_classification_counts" => gate_summary_counts(gates, "classification"),
      "gate_ids_by_status" => gate_summary_id_map(gates, "status"),
      "gate_ids_by_classification" => gate_summary_id_map(gates, "classification"),
      "passed_gate_ids" => gate_summary_ids(gates, "passed"),
      "review_required_gate_ids" => gate_summary_ids(gates, "review_required"),
      "analysis_only_gate_ids" => gate_summary_ids(gates, "analysis_only"),
      "blocked_gate_ids" => gate_summary_ids(gates, "blocked"),
      "non_passed_gate_ids" => Enum.map(non_passed_gates, & &1["id"]),
      "non_passed_gates" => non_passed_gates,
      "gates" => gates,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_readiness_gate_summary_routes_only",
        "operational_readiness_gate_summary_does_not_approve_or_import"
      ]
    }
  end

  defp gate_summary_counts(gates, field) do
    gates
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp gate_summary_id_map(gates, field) do
    gates
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} ->
      ids =
        ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {key, ids}
    end)
  end

  defp gate_summary_ids(gates, status) do
    gates
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(& &1["id"])
  end

  defp summary_gate_counts(gates) do
    %{
      gate_count: length(gates),
      passed_gate_count: gate_count(gates, "passed"),
      review_gate_count: gate_count(gates, "review_required"),
      analysis_gate_count: gate_count(gates, "analysis_only"),
      blocked_gate_count: gate_count(gates, "blocked")
    }
  end

  defp execution_boundary_summary_from_report(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    operational_mode_gate = Enum.find(gates, &(&1["id"] == "operational_mode"))
    non_passed_gates = Enum.reject(gates, &(&1["status"] == "passed"))
    import_eligible? = report["import_classification"] == "importable"
    gate_counts = summary_gate_counts(gates)

    %{
      "schema_contract" => @execution_boundary_summary_schema_contract,
      "model" => "artifact_only_operational_execution_boundary_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => import_eligible?,
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(report["import_classification"]),
      "analysis_mode" => Map.get(operational_mode_gate || %{}, "analysis_mode"),
      "analysis_mode_source" => Map.get(operational_mode_gate || %{}, "analysis_mode_source"),
      "operational_mode_gate" => operational_mode_gate,
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gate_ids" => Enum.map(non_passed_gates, & &1["id"]),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_execution_boundary_summary_routes_only",
        "operational_execution_boundary_summary_does_not_execute_or_import"
      ]
    }
    |> compact_map()
  end

  defp execution_boundary("importable"), do: "adapter_handoff_only"
  defp execution_boundary("review_only"), do: "operator_review_required_before_import"
  defp execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"
  defp execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp quality_gate_report_from_readiness(%{} = readiness_report) do
    gates = Map.get(readiness_report, "gates", []) |> Enum.filter(&is_map/1)

    rows =
      gates
      |> Enum.with_index(1)
      |> Enum.map(fn {gate, rank} -> quality_gate_row(gate, readiness_report, rank) end)

    import_classification = import_classification(rows)

    %{
      "schema_contract" => @quality_gate_schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" =>
        quality_gate_report_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"]
        ),
      "source_artifact_type" => readiness_report["source_artifact_type"],
      "source_artifact_id" => readiness_report["source_artifact_id"],
      "source_readiness_report_id" => readiness_report["report_id"],
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(import_classification),
      "gate_count" => length(rows),
      "passed_gate_count" => gate_count(rows, "passed"),
      "review_gate_count" => gate_count(rows, "review_required"),
      "analysis_gate_count" => gate_count(rows, "analysis_only"),
      "blocked_gate_count" => gate_count(rows, "blocked"),
      "gate_status_counts" => gate_summary_counts(rows, "status"),
      "gate_classification_counts" => gate_summary_counts(rows, "classification"),
      "gate_ids_by_status" => quality_gate_ids_by(rows, "status"),
      "gate_ids_by_classification" => quality_gate_ids_by(rows, "classification"),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by(rows, "status"),
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by(rows, "classification"),
      "passed_gate_ids" => quality_gate_ids(rows, "passed"),
      "review_required_gate_ids" => quality_gate_ids(rows, "review_required"),
      "analysis_only_gate_ids" => quality_gate_ids(rows, "analysis_only"),
      "blocked_gate_ids" => quality_gate_ids(rows, "blocked"),
      "rows" => rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "model_limits" => [
        "quality_gate_report_derives_classification_from_gate_rows",
        "quality_gate_report_does_not_approve_or_import"
      ]
    }
  end

  defp quality_gate_summary_from_report(%{} = quality_gate_report) do
    report = stringify_keys(quality_gate_report)
    rows = rows(report)
    non_passed_rows = Enum.reject(rows, &(&1["status"] == "passed"))

    %{
      "schema_contract" => @quality_gate_summary_schema_contract,
      "model" => "artifact_only_quality_gate_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "source_quality_gate_report_id" => report["report_id"],
      "source_readiness_report_id" => report["source_readiness_report_id"],
      "readiness_level" => readiness_level(import_classification(rows)),
      "import_classification" => import_classification(rows),
      "status" => report_status(import_classification(rows)),
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(import_classification(rows)),
      "gate_count" => length(rows),
      "passed_gate_count" => gate_count(rows, "passed"),
      "review_gate_count" => gate_count(rows, "review_required"),
      "analysis_gate_count" => gate_count(rows, "analysis_only"),
      "blocked_gate_count" => gate_count(rows, "blocked"),
      "non_passed_gate_count" => length(non_passed_rows),
      "gate_status_counts" => gate_summary_counts(rows, "status"),
      "gate_classification_counts" => gate_summary_counts(rows, "classification"),
      "gate_ids_by_status" => quality_gate_ids_by(rows, "status"),
      "gate_ids_by_classification" => quality_gate_ids_by(rows, "classification"),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by(rows, "status"),
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by(rows, "classification"),
      "passed_gate_ids" => quality_gate_ids(rows, "passed"),
      "review_required_gate_ids" => quality_gate_ids(rows, "review_required"),
      "analysis_only_gate_ids" => quality_gate_ids(rows, "analysis_only"),
      "blocked_gate_ids" => quality_gate_ids(rows, "blocked"),
      "non_passed_gate_ids" =>
        non_passed_rows |> Enum.map(& &1["gate_id"]) |> stable_sorted_ids(),
      "non_passed_quality_gate_row_ids" =>
        non_passed_rows |> Enum.map(& &1["id"]) |> stable_sorted_ids(),
      "non_passed_rows" => non_passed_rows,
      "rows" => rows,
      "assumptions" => %{
        "source" => "quality_gate_report.v1",
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_summary_derives_classification_from_gate_rows",
        "quality_gate_summary_does_not_approve_or_import"
      ]
    }
  end

  defp quality_gate_unavailable_resource_summary_from_report(%{} = quality_gate_report) do
    resource_rows = quality_gate_report |> rows() |> resource_availability_rows()
    resource_availability_counts = resource_availability_reason_counts(resource_rows)
    unavailable_counts = unavailable_resource_reason_counts(resource_rows)
    station_counts = station_availability_reason_counts(resource_availability_counts)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(resource_rows)

    blocked_contact_ids_by_blocking_dimension =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_blocking_dimension")

    blocked_contact_ids_by_spacecraft_id =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_spacecraft_id")

    %{
      "schema_contract" => @quality_gate_unavailable_resource_summary_schema_contract,
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "resource_availability_row_count" => length(resource_rows),
      "unavailable_resource_row_count" => unavailable_resource_row_count(resource_rows),
      "unavailable_resource_pressure_count" => map_value_count(unavailable_counts),
      "unavailable_resource_reason_counts" => unavailable_counts,
      "unavailable_resource_reason_ids" => sorted_count_keys(unavailable_counts),
      "station_availability_reason_counts" => station_counts,
      "station_availability_reason_ids" => sorted_count_keys(station_counts),
      "resource_blocking_dimension_counts" =>
        resource_rows
        |> Enum.map(&Map.get(&1, "resource_blocking_dimension_counts"))
        |> merge_positive_count_maps(),
      "blocked_contact_ids_by_blocking_dimension" => blocked_contact_ids_by_blocking_dimension,
      "blocked_contact_ids_by_spacecraft_id" => blocked_contact_ids_by_spacecraft_id,
      "blocked_contact_ids_by_status" => blocked_contact_ids_by_status(resource_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(resource_rows, "status"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "resource_availability_gate_ids" =>
        resource_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_unavailable_resource_summary_routes_only",
        "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp quality_gate_operator_training_summary_from_report(%{} = quality_gate_report) do
    training_rows = quality_gate_report |> rows() |> operator_training_rows()
    requirement_counts = operator_training_requirement_counts(training_rows)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(training_rows)

    quality_gate_row_ids_by_classification =
      quality_gate_row_ids_by(training_rows, "classification")

    %{
      "schema_contract" => @quality_gate_operator_training_summary_schema_contract,
      "model" => "artifact_only_quality_gate_operator_training_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "operator_training_row_count" => length(training_rows),
      "operator_training_requirement_count" => map_value_count(requirement_counts),
      "operator_training_requirement_counts" => requirement_counts,
      "operator_training_requirement_ids" => sorted_count_keys(requirement_counts),
      "required_operator_roles" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_operator_roles"]))
        |> stable_sorted_ids(),
      "required_training_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_training_ids"]))
        |> stable_sorted_ids(),
      "required_certification_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_certification_ids"]))
        |> stable_sorted_ids(),
      "required_qualification_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_qualification_ids"]))
        |> stable_sorted_ids(),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by_classification,
      "quality_gate_ids_by_status" => quality_gate_ids_by(training_rows, "status"),
      "quality_gate_ids_by_classification" =>
        quality_gate_ids_by(training_rows, "classification"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "review_only_quality_gate_row_ids" =>
        quality_gate_row_ids_by_classification |> Map.get("review_only", []),
      "operator_training_gate_ids" =>
        training_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "operator_training_review_required" =>
        Enum.any?(training_rows, &(&1["status"] == "review_required")),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_operator_training_summary_routes_only",
        "quality_gate_operator_training_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp quality_gate_schema_validation_summary_from_report(%{} = quality_gate_report) do
    schema_rows = quality_gate_report |> rows() |> schema_validation_rows()
    schema_status_counts = schema_validation_status_counts(schema_rows)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(schema_rows)

    %{
      "schema_contract" => @quality_gate_schema_validation_summary_schema_contract,
      "model" => "artifact_only_quality_gate_schema_validation_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "schema_validation_row_count" => length(schema_rows),
      "schema_validation_pass_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_pass_count")) |> integer_sum(),
      "schema_validation_fail_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_fail_count")) |> integer_sum(),
      "schema_validation_error_count" =>
        schema_rows |> Enum.map(&Map.get(&1, "schema_validation_error_count")) |> integer_sum(),
      "schema_validation_warning_count" =>
        schema_rows
        |> Enum.map(&Map.get(&1, "schema_validation_warning_count"))
        |> integer_sum(),
      "schema_validation_remediation_count" =>
        schema_rows
        |> Enum.map(&Map.get(&1, "schema_validation_remediation_count"))
        |> integer_sum(),
      "schema_validation_status_counts" => schema_status_counts,
      "schema_validation_status_ids" => sorted_count_keys(schema_status_counts),
      "schema_validation_import_blocked" => schema_validation_blocked?(schema_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(schema_rows, "status"),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "failed_schema_validation_quality_gate_row_ids" =>
        schema_rows
        |> Enum.filter(&schema_validation_failed?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "schema_validation_gate_ids" =>
        schema_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_schema_validation_summary_routes_only",
        "quality_gate_schema_validation_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp quality_gate_import_readiness_summary_from_report(%{} = quality_gate_report) do
    import_rows = quality_gate_report |> rows() |> import_readiness_rows()
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(import_rows)

    freshness_status_counts =
      import_rows
      |> Enum.map(&Map.get(&1, "freshness_status_counts"))
      |> merge_positive_count_maps()

    import_status_counts =
      import_rows |> Enum.map(&Map.get(&1, "import_status_counts")) |> merge_positive_count_maps()

    cadence_import_status_counts =
      import_rows
      |> Enum.map(&Map.get(&1, "cadence_import_status_counts"))
      |> merge_positive_count_maps()

    %{
      "schema_contract" => @quality_gate_import_readiness_summary_schema_contract,
      "model" => "artifact_only_quality_gate_import_readiness_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "import_readiness_row_count" => length(import_rows),
      "ready_for_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "ready_for_import_count")) |> integer_sum(),
      "manifest_review_required_count" =>
        import_rows
        |> Enum.map(&Map.get(&1, "manifest_review_required_count"))
        |> integer_sum(),
      "blocked_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "blocked_import_count")) |> integer_sum(),
      "missing_import_count" =>
        import_rows |> Enum.map(&Map.get(&1, "missing_import_count")) |> integer_sum(),
      "invalid_cadence_import_count" =>
        import_rows
        |> Enum.map(&Map.get(&1, "invalid_cadence_import_count"))
        |> integer_sum(),
      "current_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "current_freshness_count")) |> integer_sum(),
      "stale_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "stale_freshness_count")) |> integer_sum(),
      "unknown_freshness_count" =>
        import_rows |> Enum.map(&Map.get(&1, "unknown_freshness_count")) |> integer_sum(),
      "freshness_status_counts" => freshness_status_counts,
      "freshness_status_ids" => sorted_count_keys(freshness_status_counts),
      "import_status_counts" => import_status_counts,
      "import_status_ids" => sorted_count_keys(import_status_counts),
      "cadence_import_status_counts" => cadence_import_status_counts,
      "cadence_import_status_ids" => sorted_count_keys(cadence_import_status_counts),
      "freshness_review_required" => freshness_review_required?(import_rows),
      "import_preparation_required" => import_preparation_required?(import_rows),
      "import_blocked" => import_blocked?(import_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(import_rows, "status"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "ready_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("passed", []),
      "analysis_only_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("analysis_only", []),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&freshness_review_required?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "import_preparation_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&import_preparation_required?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "blocked_import_quality_gate_row_ids" =>
        import_rows
        |> Enum.filter(&import_blocked?/1)
        |> Enum.map(& &1["id"])
        |> stable_sorted_ids(),
      "import_readiness_gate_ids" =>
        import_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_import_readiness_summary_routes_only",
        "quality_gate_import_readiness_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp quality_gate_row(gate, readiness_report, rank) do
    %{
      "id" =>
        quality_gate_row_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"],
          gate["id"],
          rank
        ),
      "rank" => rank,
      "gate_id" => gate["id"],
      "status" => gate["status"],
      "classification" => gate["classification"],
      "reason" => gate["reason"],
      "analysis_mode" => gate["analysis_mode"],
      "analysis_mode_source" => gate["analysis_mode_source"],
      "source_operational_readiness_gate" => gate
    }
    |> Map.merge(quality_gate_row_context(gate))
    |> compact_map()
  end

  defp quality_gate_row_context(%{"id" => "resource_availability"} = gate) do
    resource_availability_reason_counts =
      gate
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => gate["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" =>
        gate
        |> Map.get("resource_blocking_dimension_counts", %{})
        |> positive_count_map(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_blocking_dimension", %{})
        |> stable_id_array_map(),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_spacecraft_id", %{})
        |> stable_id_array_map(),
      "resource_source_quality_counts" =>
        gate
        |> Map.get("resource_source_quality_counts", %{})
        |> positive_count_map(),
      "resource_trust_boundary_status_counts" =>
        gate
        |> Map.get("resource_trust_boundary_status_counts", %{})
        |> positive_count_map()
    }
  end

  defp quality_gate_row_context(%{"id" => "cadence_import"} = gate) do
    cadence_import_gate_context(gate)
  end

  defp quality_gate_row_context(%{"id" => "adapter_boundary"} = gate) do
    adapter_boundary_gate_context(gate)
  end

  defp quality_gate_row_context(%{"id" => "operator_training"} = gate) do
    operator_training_gate_context(gate)
  end

  defp quality_gate_row_context(_gate), do: %{}

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp unavailable_resource_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in unavailable_resource_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in station_availability_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_counts(counts) when is_map(counts) do
    counts
    |> positive_count_map()
    |> Map.filter(fn {reason, _count} -> reason in station_availability_reasons() end)
  end

  defp resource_availability_rows(rows) do
    Enum.filter(rows, &(&1["gate_id"] == "resource_availability"))
  end

  defp operator_training_rows(rows) do
    Enum.filter(rows, &(&1["gate_id"] == "operator_training"))
  end

  defp operator_training_requirement_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "operator_training_requirement_counts"))
    |> merge_positive_count_maps()
  end

  defp unavailable_resource_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
      |> Map.filter(fn {reason, _count} -> reason in unavailable_resource_reasons() end)
    end)
    |> merge_positive_count_maps()
  end

  defp resource_availability_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
    end)
    |> merge_positive_count_maps()
  end

  defp unavailable_resource_row_count(rows) do
    Enum.count(rows, fn row ->
      row
      |> Map.get("unavailable_resource_reason_ids", [])
      |> list_value()
      |> Enum.any?()
    end)
  end

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp blocked_contact_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_list_maps()
  end

  defp blocked_contact_ids_by_status(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      status = normalized_evidence_string(row["status"])
      ids = row_blocked_contact_ids(row)

      if status && ids != [] do
        Map.update(acc, status, ids, fn current ->
          (current ++ ids)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      else
        acc
      end
    end)
  end

  defp row_blocked_contact_ids(row) do
    [
      Map.get(row, "resource_blocked_contact_ids_by_blocking_dimension"),
      Map.get(row, "resource_blocked_contact_ids_by_spacecraft_id")
    ]
    |> merge_string_list_maps()
    |> Map.values()
    |> List.flatten()
    |> stable_sorted_ids()
  end

  defp schema_validation_rows(rows) do
    Enum.filter(rows, fn row ->
      row["gate_id"] == "cadence_import" and schema_validation_context?(row)
    end)
  end

  defp schema_validation_context?(row) do
    map_value_count(row["schema_validation_status_counts"]) > 0 or
      Enum.any?(
        ~w(
          schema_validation_pass_count
          schema_validation_fail_count
          schema_validation_error_count
          schema_validation_warning_count
          schema_validation_remediation_count
        ),
        fn field -> integer_value(row[field]) |> positive_integer?() end
      )
  end

  defp schema_validation_status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "schema_validation_status_counts"))
    |> merge_positive_count_maps()
  end

  defp schema_validation_blocked?(rows), do: Enum.any?(rows, &schema_validation_failed?/1)

  defp schema_validation_failed?(row) do
    integer_value(row["schema_validation_fail_count"]) |> positive_integer?() or
      integer_value(row["schema_validation_error_count"]) |> positive_integer?()
  end

  defp import_readiness_rows(rows) do
    Enum.filter(rows, fn row ->
      row["gate_id"] == "cadence_import" and import_readiness_context?(row)
    end)
  end

  defp import_readiness_context?(row) do
    map_value_count(row["freshness_status_counts"]) > 0 or
      map_value_count(row["import_status_counts"]) > 0 or
      map_value_count(row["cadence_import_status_counts"]) > 0 or
      Enum.any?(
        ~w(
          ready_for_import_count
          manifest_review_required_count
          blocked_import_count
          missing_import_count
          invalid_cadence_import_count
          current_freshness_count
          stale_freshness_count
          unknown_freshness_count
        ),
        fn field -> integer_value(row[field]) |> positive_integer?() end
      )
  end

  defp freshness_review_required?(rows) when is_list(rows),
    do: Enum.any?(rows, &freshness_review_required?/1)

  defp freshness_review_required?(row) do
    integer_value(row["stale_freshness_count"]) |> positive_integer?() or
      integer_value(row["unknown_freshness_count"]) |> positive_integer?()
  end

  defp import_preparation_required?(rows) when is_list(rows),
    do: Enum.any?(rows, &import_preparation_required?/1)

  defp import_preparation_required?(row) do
    integer_value(row["manifest_review_required_count"]) |> positive_integer?() or
      integer_value(row["missing_import_count"]) |> positive_integer?()
  end

  defp import_blocked?(rows) when is_list(rows), do: Enum.any?(rows, &import_blocked?/1)

  defp import_blocked?(row) do
    integer_value(row["blocked_import_count"]) |> positive_integer?() or
      integer_value(row["invalid_cadence_import_count"]) |> positive_integer?()
  end

  defp positive_integer?(value) when is_integer(value), do: value > 0
  defp positive_integer?(_value), do: false

  defp integer_sum(values) do
    values
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp unavailable_resource_reasons do
    ~w(
      antenna_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp station_availability_reasons do
    ~w(
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
    )
  end

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_ids(rows, status) do
    rows
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(& &1["gate_id"])
    |> stable_sorted_ids()
  end

  defp quality_gate_row_ids_by_status(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "status"), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp quality_gate_report_id(source_artifact_type, source_artifact_id) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown"]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp quality_gate_row_id(source_artifact_type, source_artifact_id, gate_id, rank) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown", gate_id, rank]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp review_package_for(%{"schema_contract" => "operator_review_package.v1"} = package),
    do: package

  defp review_package_for(%{"schema_contract" => "cadence_import_manifest.v1"}), do: nil

  defp review_package_for(%{} = artifact), do: OrbitalDynamics.operator_review_package(artifact)

  defp import_manifest_for(
         %{"schema_contract" => "cadence_import_manifest.v1"} = manifest,
         _package
       ),
       do: manifest

  defp import_manifest_for(_artifact, %{} = review_package),
    do: CadenceImport.manifest(review_package)

  defp import_manifest_for(%{} = artifact, _package), do: CadenceImport.manifest(artifact)

  defp build_report(artifact, review_package, import_manifest, opts) do
    source_artifact_type = source_artifact_type(artifact, review_package, import_manifest)
    source_artifact_id = source_artifact_id(artifact, review_package, import_manifest)
    evidence = evidence(artifact, review_package, import_manifest)

    gates =
      [
        source_contract_gate(source_artifact_type),
        operational_mode_gate(artifact, opts),
        adapter_boundary_gate(evidence),
        mission_policy_gate(evidence),
        operator_training_gate(evidence),
        resource_availability_gate(evidence),
        operator_review_gate(evidence),
        cadence_import_gate(evidence)
      ]
      |> Enum.reject(&is_nil/1)

    import_classification = import_classification(gates)

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => report_id(source_artifact_type, source_artifact_id),
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "gate_count" => length(gates),
      "passed_gate_count" => gate_count(gates, "passed"),
      "review_gate_count" => gate_count(gates, "review_required"),
      "analysis_gate_count" => gate_count(gates, "analysis_only"),
      "blocked_gate_count" => gate_count(gates, "blocked"),
      "gates" => gates,
      "evidence" => evidence,
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => capabilities().known_limits |> Enum.map(&Atom.to_string/1)
    }
  end

  defp source_contract_gate(nil) do
    gate(
      "source_contract",
      "blocked",
      "blocked",
      "source artifact type could not be inferred"
    )
  end

  defp source_contract_gate(_source_artifact_type) do
    gate(
      "source_contract",
      "passed",
      "importable",
      "source artifact type is declared"
    )
  end

  defp operational_mode_gate(artifact, opts) do
    case analysis_only_decision(artifact, opts) do
      nil ->
        gate(
          "operational_mode",
          "passed",
          "importable",
          "artifact is not marked as simulation, rehearsal, trade study, or not-for-execution"
        )

      {mode, source, reason} ->
        gate(
          "operational_mode",
          "analysis_only",
          "analysis_only",
          reason,
          %{"analysis_mode" => mode, "analysis_mode_source" => source}
        )
    end
  end

  defp adapter_boundary_gate(evidence) do
    cond do
      evidence["adapter_trust_boundary_untrusted_count"] > 0 ->
        gate(
          "adapter_boundary",
          "blocked",
          "blocked",
          "adapter import context declares untrusted trust-boundary evidence",
          adapter_boundary_gate_context(evidence)
        )

      evidence["adapter_trust_boundary_missing_count"] > 0 ->
        gate(
          "adapter_boundary",
          "review_required",
          "review_only",
          "adapter import context is missing a declared trust boundary",
          adapter_boundary_gate_context(evidence)
        )

      evidence["adapter_context_count"] > 0 ->
        gate(
          "adapter_boundary",
          "passed",
          "importable",
          "adapter import context declares trust boundary evidence",
          adapter_boundary_gate_context(evidence)
        )

      true ->
        gate(
          "adapter_boundary",
          "passed",
          "importable",
          "no adapter-specific import boundary context was declared"
        )
    end
  end

  defp adapter_boundary_gate_context(evidence) do
    %{
      "adapter_context_count" => evidence["adapter_context_count"],
      "adapter_trust_boundary_declared_count" =>
        evidence["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" => evidence["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" =>
        evidence["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" => evidence["adapter_boundary_status_counts"]
    }
  end

  defp mission_policy_gate(evidence) do
    cond do
      evidence["policy_blocked_count"] > 0 ->
        gate(
          "mission_policy",
          "blocked",
          "blocked",
          "mission-policy evidence blocks import eligibility",
          mission_policy_gate_context(evidence)
        )

      evidence["policy_review_required_count"] > 0 ->
        gate(
          "mission_policy",
          "review_required",
          "review_only",
          "mission-policy evidence requires operator review before import",
          mission_policy_gate_context(evidence)
        )

      evidence["policy_decision_count"] > 0 ->
        gate(
          "mission_policy",
          "passed",
          "importable",
          "mission-policy evidence is auto-approvable",
          mission_policy_gate_context(evidence)
        )

      true ->
        nil
    end
  end

  defp mission_policy_gate_context(evidence) do
    %{
      "policy_decision_count" => evidence["policy_decision_count"],
      "policy_classification_counts" => evidence["policy_classification_counts"]
    }
  end

  defp operator_training_gate(evidence) do
    case evidence["operator_training_requirement_count"] do
      count when is_integer(count) and count > 0 ->
        gate(
          "operator_training",
          "review_required",
          "review_only",
          "operator training or qualification evidence requires role-qualified review before import",
          operator_training_gate_context(evidence)
        )

      _count ->
        nil
    end
  end

  defp operator_training_gate_context(evidence) do
    %{
      "operator_training_requirement_count" => evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" => evidence["operator_training_requirement_counts"],
      "required_operator_roles" => evidence["required_operator_roles"],
      "required_training_ids" => evidence["required_training_ids"],
      "required_certification_ids" => evidence["required_certification_ids"],
      "required_qualification_ids" => evidence["required_qualification_ids"]
    }
  end

  defp resource_availability_gate(evidence) do
    case evidence["resource_availability_pressure_count"] do
      count when is_integer(count) and count > 0 ->
        gate(
          "resource_availability",
          "review_required",
          "review_only",
          "resource availability evidence requires operator review before import",
          resource_availability_gate_context(evidence)
        )

      _count ->
        nil
    end
  end

  defp resource_availability_gate_context(evidence) do
    resource_availability_reason_counts =
      evidence
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" => evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => evidence["resource_trust_boundary_status_counts"]
    }
  end

  defp operator_review_gate(evidence) do
    cond do
      evidence["blocked_review_count"] > 0 ->
        gate(
          "operator_review",
          "blocked",
          "blocked",
          "operator-review evidence includes blocked approval status"
        )

      evidence["review_required_count"] > 0 ->
        gate(
          "operator_review",
          "review_required",
          "review_only",
          "operator-review evidence requires human review before import"
        )

      evidence["review_row_count"] > 0 ->
        gate(
          "operator_review",
          "passed",
          "importable",
          "operator-review rows have no blocked or review-required status"
        )

      evidence["import_row_count"] > 0 ->
        gate(
          "operator_review",
          "passed",
          "importable",
          "Cadence import rows carry source review handoff evidence"
        )

      true ->
        gate(
          "operator_review",
          "analysis_only",
          "analysis_only",
          "no operator-review rows were available"
        )
    end
  end

  defp cadence_import_gate(evidence) do
    cond do
      evidence["blocked_import_count"] > 0 or evidence["invalid_cadence_import_count"] > 0 ->
        gate(
          "cadence_import",
          "blocked",
          "blocked",
          "Cadence import evidence is blocked or invalid",
          cadence_import_gate_context(evidence)
        )

      evidence["schema_validation_fail_count"] > 0 or
          evidence["schema_validation_error_count"] > 0 ->
        gate(
          "cadence_import",
          "blocked",
          "blocked",
          "source schema-validation evidence failed",
          cadence_import_gate_context(evidence)
        )

      evidence["manifest_review_required_count"] > 0 or evidence["missing_import_count"] > 0 ->
        gate(
          "cadence_import",
          "review_required",
          "review_only",
          "Cadence import evidence requires review or import preparation",
          cadence_import_gate_context(evidence)
        )

      evidence["stale_freshness_count"] > 0 or evidence["unknown_freshness_count"] > 0 ->
        gate(
          "cadence_import",
          "review_required",
          "review_only",
          "source freshness evidence is stale or unknown",
          cadence_import_gate_context(evidence)
        )

      evidence["ready_for_import_count"] > 0 ->
        gate(
          "cadence_import",
          "passed",
          "importable",
          "Cadence import manifest has ready-for-import rows",
          cadence_import_gate_context(evidence)
        )

      true ->
        gate(
          "cadence_import",
          "analysis_only",
          "analysis_only",
          "no ready-for-import rows were available",
          cadence_import_gate_context(evidence)
        )
    end
  end

  defp cadence_import_gate_context(evidence) do
    %{
      "ready_for_import_count" => evidence["ready_for_import_count"],
      "manifest_review_required_count" => evidence["manifest_review_required_count"],
      "blocked_import_count" => evidence["blocked_import_count"],
      "missing_import_count" => evidence["missing_import_count"],
      "invalid_cadence_import_count" => evidence["invalid_cadence_import_count"],
      "current_freshness_count" => evidence["current_freshness_count"],
      "stale_freshness_count" => evidence["stale_freshness_count"],
      "unknown_freshness_count" => evidence["unknown_freshness_count"],
      "freshness_status_counts" => positive_count_map(evidence["freshness_status_counts"]),
      "schema_validation_pass_count" => evidence["schema_validation_pass_count"],
      "schema_validation_fail_count" => evidence["schema_validation_fail_count"],
      "schema_validation_error_count" => evidence["schema_validation_error_count"],
      "schema_validation_warning_count" => evidence["schema_validation_warning_count"],
      "schema_validation_remediation_count" => evidence["schema_validation_remediation_count"],
      "schema_validation_status_counts" =>
        positive_count_map(evidence["schema_validation_status_counts"]),
      "import_status_counts" => positive_count_map(evidence["import_status_counts"]),
      "cadence_import_status_counts" =>
        positive_count_map(evidence["cadence_import_status_counts"])
    }
  end

  defp gate(id, status, classification, reason, context \\ %{}) do
    %{
      "id" => id,
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
    |> Map.merge(context)
  end

  defp evidence(artifact, review_package, import_manifest) do
    review_rows = rows(review_package)
    import_rows = rows(import_manifest)
    review_type_counts = row_counts(review_rows, "review_type")
    approval_status_counts = row_counts(review_rows, "approval_status")
    import_action_counts = row_counts(import_rows, "import_action")
    source_review_type_counts = row_counts(import_rows, "source_review_type")
    import_status_counts = row_counts(import_rows, "import_status")
    cadence_import_status_counts = row_counts(import_rows, "cadence_import_status")
    freshness_status_counts = freshness_status_counts(artifact, review_rows, import_rows)

    schema_validation_status_counts =
      schema_validation_status_counts(artifact, review_rows, import_rows)

    source_model_counts = source_model_counts(artifact, review_rows, import_rows)
    source_model_limit_counts = source_model_limit_counts(artifact, review_rows, import_rows)

    policy_classification_counts =
      policy_classification_counts(artifact, review_rows, import_rows)

    adapter_boundary_status_counts =
      adapter_boundary_status_counts(artifact, review_rows, import_rows)

    operator_training_context =
      operator_training_context(artifact, review_rows, import_rows)

    resource_availability_reason_counts =
      resource_availability_reason_counts(review_rows, import_rows)

    resource_blocking_dimension_counts =
      resource_blocking_dimension_counts(review_rows, import_rows)

    resource_blocked_contact_ids_by_blocking_dimension =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_blocking_dimension",
        "resource_blocking_dimension"
      )

    resource_blocked_contact_ids_by_spacecraft_id =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_spacecraft_id",
        "spacecraft_id"
      )

    resource_source_quality_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_source_quality")

    resource_trust_boundary_status_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_trust_boundary_status")

    %{
      "review_row_count" => length(review_rows),
      "import_row_count" => length(import_rows),
      "review_required_count" =>
        count_values(approval_status_counts, ["operator_review_required", "pending"]),
      "blocked_review_count" => count_values(approval_status_counts, ["blocked_by_policy"]),
      "ready_for_import_count" => count_values(import_status_counts, ["ready_for_import"]),
      "manifest_review_required_count" =>
        count_values(import_status_counts, ["review_required_before_import"]),
      "blocked_import_count" =>
        count_values(import_status_counts, ["blocked_missing_cadence_import"]),
      "missing_import_count" => count_values(cadence_import_status_counts, ["missing"]),
      "invalid_cadence_import_count" => count_values(cadence_import_status_counts, ["invalid"]),
      "current_freshness_count" => count_values(freshness_status_counts, ["current"]),
      "stale_freshness_count" => count_values(freshness_status_counts, ["stale"]),
      "unknown_freshness_count" => count_values(freshness_status_counts, ["unknown"]),
      "schema_validation_pass_count" => count_values(schema_validation_status_counts, ["pass"]),
      "schema_validation_fail_count" => count_values(schema_validation_status_counts, ["fail"]),
      "schema_validation_error_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "error_count"),
      "schema_validation_warning_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "warning_count"),
      "schema_validation_remediation_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "remediation_count"),
      "source_model_count" => map_value_count(source_model_counts),
      "source_model_limit_count" => map_value_count(source_model_limit_counts),
      "policy_decision_count" => map_value_count(policy_classification_counts),
      "policy_auto_approvable_count" =>
        count_values(policy_classification_counts, ["auto_approvable"]),
      "policy_review_required_count" =>
        count_values(policy_classification_counts, ["operator_review_required"]),
      "policy_blocked_count" => count_values(policy_classification_counts, ["blocked_by_policy"]),
      "adapter_context_count" => map_value_count(adapter_boundary_status_counts),
      "adapter_trust_boundary_declared_count" =>
        count_values(adapter_boundary_status_counts, ["declared"]),
      "adapter_trust_boundary_missing_count" =>
        count_values(adapter_boundary_status_counts, ["missing"]),
      "adapter_trust_boundary_untrusted_count" =>
        count_values(adapter_boundary_status_counts, ["untrusted"]),
      "operator_training_requirement_count" =>
        operator_training_context["operator_training_requirement_count"],
      "resource_availability_pressure_count" =>
        map_value_count(resource_availability_reason_counts),
      "resource_blocking_dimension_count" => map_value_count(resource_blocking_dimension_counts),
      "review_type_counts" => review_type_counts,
      "approval_status_counts" => approval_status_counts,
      "import_action_counts" => import_action_counts,
      "source_review_type_counts" => source_review_type_counts,
      "import_status_counts" => import_status_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "freshness_status_counts" => freshness_status_counts,
      "schema_validation_status_counts" => schema_validation_status_counts,
      "source_model_counts" => source_model_counts,
      "source_model_limit_counts" => source_model_limit_counts,
      "policy_classification_counts" => policy_classification_counts,
      "adapter_boundary_status_counts" => adapter_boundary_status_counts,
      "operator_training_requirement_counts" =>
        operator_training_context["operator_training_requirement_counts"],
      "required_operator_roles" => operator_training_context["required_operator_roles"],
      "required_training_ids" => operator_training_context["required_training_ids"],
      "required_certification_ids" => operator_training_context["required_certification_ids"],
      "required_qualification_ids" => operator_training_context["required_qualification_ids"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" => resource_blocking_dimension_counts,
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        resource_blocked_contact_ids_by_blocking_dimension,
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        resource_blocked_contact_ids_by_spacecraft_id,
      "resource_source_quality_counts" => resource_source_quality_counts,
      "resource_trust_boundary_status_counts" => resource_trust_boundary_status_counts
    }
  end

  defp rows(%{"rows" => rows}) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  defp rows(_artifact), do: []

  defp row_counts(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp freshness_status_counts(artifact, review_rows, import_rows) do
    (artifact_statuses(artifact) ++
       row_freshness_statuses(review_rows) ++ row_freshness_statuses(import_rows))
    |> Enum.map(&normalized_freshness_status/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_statuses(%{"schema_contract" => "freshness_report.v1", "status" => status}) do
    [status]
  end

  defp artifact_statuses(%{} = artifact) do
    [
      get_in(artifact, ["freshness_report", "status"]),
      get_in(artifact, ["source_freshness_report", "status"])
    ]
  end

  defp artifact_statuses(_artifact), do: []

  defp row_freshness_statuses(rows) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row["freshness_status"],
        get_in(row, ["source_freshness_report", "status"]),
        get_in(row, ["source_review_row", "freshness_status"]),
        get_in(row, ["source_review_row", "source_freshness_report", "status"])
      ])
    end)
  end

  defp first_present(values) do
    Enum.find(values, &(&1 not in [nil, ""]))
  end

  defp normalized_freshness_status(value) when value in ["current", "stale", "unknown"], do: value

  defp normalized_freshness_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      status when status in ["current", "stale", "unknown"] -> status
      _status -> nil
    end
  end

  defp normalized_freshness_status(_value), do: nil

  defp schema_validation_status_counts(artifact, review_rows, import_rows) do
    (artifact_schema_validation_statuses(artifact) ++
       row_schema_validation_statuses(review_rows) ++ row_schema_validation_statuses(import_rows))
    |> Enum.map(&normalized_schema_validation_status/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_schema_validation_statuses(%{
         "schema_contract" => "schema_validation_report.v1",
         "status" => status
       }) do
    [status]
  end

  defp artifact_schema_validation_statuses(%{} = artifact) do
    [
      get_in(artifact, ["schema_validation_report", "status"]),
      get_in(artifact, ["source_schema_validation_report", "status"])
    ]
  end

  defp artifact_schema_validation_statuses(_artifact), do: []

  defp row_schema_validation_statuses(rows) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row["validation_status"],
        row["schema_validation_gate_status"],
        get_in(row, ["source_schema_validation_report", "status"]),
        get_in(row, ["source_review_row", "validation_status"]),
        get_in(row, ["source_review_row", "source_schema_validation_report", "status"])
      ])
    end)
  end

  defp normalized_schema_validation_status(value) when value in ["pass", "fail"], do: value

  defp normalized_schema_validation_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      status when status in ["pass", "fail"] -> status
      _status -> nil
    end
  end

  defp normalized_schema_validation_status(_value), do: nil

  defp schema_validation_issue_count(artifact, review_rows, import_rows, field) do
    (artifact_schema_validation_issue_counts(artifact, field) ++
       row_schema_validation_issue_counts(review_rows, field) ++
       row_schema_validation_issue_counts(import_rows, field))
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp artifact_schema_validation_issue_counts(
         %{"schema_contract" => "schema_validation_report.v1"} = report,
         field
       ) do
    [Map.get(report, field)]
  end

  defp artifact_schema_validation_issue_counts(%{} = artifact, field) do
    [
      get_in(artifact, ["schema_validation_report", field]),
      get_in(artifact, ["source_schema_validation_report", field])
    ]
  end

  defp artifact_schema_validation_issue_counts(_artifact, _field), do: []

  defp row_schema_validation_issue_counts(rows, field) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row[field],
        get_in(row, ["source_schema_validation_report", field]),
        get_in(row, ["source_review_row", field]),
        get_in(row, ["source_review_row", "source_schema_validation_report", field])
      ])
    end)
  end

  defp integer_value(value) when is_integer(value), do: value
  defp integer_value(value) when is_float(value), do: trunc(value)

  defp integer_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse_error -> nil
    end
  end

  defp integer_value(_value), do: nil

  defp source_model_counts(artifact, review_rows, import_rows) do
    (artifact_model_values(artifact) ++
       row_model_values(review_rows) ++ row_model_values(import_rows))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_model_values(%{} = artifact) do
    [
      artifact["model"],
      get_in(artifact, ["freshness_report", "model"]),
      get_in(artifact, ["source_freshness_report", "model"]),
      get_in(artifact, ["schema_validation_report", "model"]),
      get_in(artifact, ["source_schema_validation_report", "model"])
    ]
  end

  defp artifact_model_values(_artifact), do: []

  defp row_model_values(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["model"],
        get_in(row, ["source_freshness_report", "model"]),
        get_in(row, ["source_schema_validation_report", "model"]),
        get_in(row, ["source_review_row", "model"]),
        get_in(row, ["source_review_row", "source_freshness_report", "model"]),
        get_in(row, ["source_review_row", "source_schema_validation_report", "model"])
      ]
    end)
  end

  defp source_model_limit_counts(artifact, review_rows, import_rows) do
    (artifact_model_limits(artifact) ++
       row_model_limits(review_rows) ++ row_model_limits(import_rows))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_model_limits(%{} = artifact) do
    list_value(artifact["model_limits"]) ++
      list_value(get_in(artifact, ["freshness_report", "model_limits"])) ++
      list_value(get_in(artifact, ["source_freshness_report", "model_limits"])) ++
      list_value(get_in(artifact, ["schema_validation_report", "model_limits"])) ++
      list_value(get_in(artifact, ["source_schema_validation_report", "model_limits"]))
  end

  defp artifact_model_limits(_artifact), do: []

  defp row_model_limits(rows) do
    rows
    |> Enum.flat_map(fn row ->
      list_value(row["model_limits"]) ++
        list_value(get_in(row, ["source_freshness_report", "model_limits"])) ++
        list_value(get_in(row, ["source_schema_validation_report", "model_limits"])) ++
        list_value(get_in(row, ["source_review_row", "model_limits"])) ++
        list_value(get_in(row, ["source_review_row", "source_freshness_report", "model_limits"])) ++
        list_value(
          get_in(row, ["source_review_row", "source_schema_validation_report", "model_limits"])
        )
    end)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(value) when value in [nil, ""], do: []
  defp list_value(value), do: [value]

  defp normalized_evidence_string(value) when value in [nil, :null], do: nil

  defp normalized_evidence_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalized_evidence_string(value) when is_atom(value), do: value |> Atom.to_string()
  defp normalized_evidence_string(_value), do: nil

  defp map_value_count(counts) when is_map(counts) do
    counts
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end

  defp policy_classification_counts(artifact, review_rows, import_rows) do
    (artifact_policy_classifications(artifact) ++
       row_policy_classifications(review_rows) ++ row_policy_classifications(import_rows))
    |> Enum.map(&normalized_policy_classification/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_policy_classifications(%{"schema_contract" => "policy_decision.v1"} = decision) do
    [decision["classification"]]
  end

  defp artifact_policy_classifications(%{} = artifact) do
    [
      artifact["policy_classification"],
      get_in(artifact, ["policy_decision", "classification"]),
      get_in(artifact, ["source_policy_decision", "classification"])
    ]
  end

  defp artifact_policy_classifications(_artifact), do: []

  defp row_policy_classifications(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["policy_classification"],
        get_in(row, ["policy_decision", "classification"]),
        get_in(row, ["source_policy_decision", "classification"]),
        get_in(row, ["source_review_row", "policy_classification"]),
        get_in(row, ["source_review_row", "policy_decision", "classification"]),
        get_in(row, ["source_review_row", "source_policy_decision", "classification"])
      ]
    end)
  end

  defp normalized_policy_classification(value)
       when value in ["auto_approvable", "operator_review_required", "blocked_by_policy"],
       do: value

  defp normalized_policy_classification(value) do
    value
    |> normalized_evidence_string()
    |> case do
      classification
      when classification in [
             "auto_approvable",
             "operator_review_required",
             "blocked_by_policy"
           ] ->
        classification

      _classification ->
        nil
    end
  end

  defp operator_training_context(artifact, review_rows, import_rows) do
    maps = operator_training_evidence_maps(artifact, review_rows, import_rows)

    roles =
      maps
      |> Enum.flat_map(&operator_training_role_values/1)
      |> stable_sorted_evidence_values()

    training_ids =
      maps
      |> Enum.flat_map(&operator_training_training_values/1)
      |> stable_sorted_evidence_values()

    certification_ids =
      maps
      |> Enum.flat_map(&operator_training_certification_values/1)
      |> stable_sorted_evidence_values()

    qualification_ids =
      maps
      |> Enum.flat_map(&operator_training_qualification_values/1)
      |> stable_sorted_evidence_values()

    requirement_counts =
      %{
        "operator_role" => length(roles),
        "training" => length(training_ids),
        "certification" => length(certification_ids),
        "qualification" => length(qualification_ids)
      }
      |> Enum.filter(fn {_kind, count} -> count > 0 end)
      |> Map.new()

    %{
      "operator_training_requirement_count" => map_value_count(requirement_counts),
      "operator_training_requirement_counts" => requirement_counts,
      "required_operator_roles" => roles,
      "required_training_ids" => training_ids,
      "required_certification_ids" => certification_ids,
      "required_qualification_ids" => qualification_ids
    }
  end

  defp operator_training_evidence_maps(artifact, review_rows, import_rows) do
    [artifact | review_rows ++ import_rows]
    |> Enum.flat_map(&operator_training_nested_maps/1)
    |> Enum.filter(&is_map/1)
  end

  defp operator_training_nested_maps(%{} = row) do
    [
      row,
      row["operator_training"],
      row["training_requirements"],
      row["source_review_row"],
      row["source_operational_readiness_gate"],
      get_in(row, ["source_review_row", "operator_training"]),
      get_in(row, ["source_review_row", "training_requirements"]),
      get_in(row, ["source_review_row", "source_operational_readiness_gate"])
    ]
    |> Enum.filter(&is_map/1)
  end

  defp operator_training_nested_maps(_row), do: []

  defp operator_training_role_values(row) do
    list_values(row, ~w(
      required_operator_role
      required_operator_roles
      required_role
      required_roles
      operator_role
      operator_roles
    ))
  end

  defp operator_training_training_values(row) do
    list_values(row, ~w(
      required_training_id
      required_training_ids
      required_operator_training_id
      required_operator_training_ids
      training_requirement_id
      training_requirement_ids
    ))
  end

  defp operator_training_certification_values(row) do
    list_values(row, ~w(
      required_certification_id
      required_certification_ids
      required_operator_certification_id
      required_operator_certification_ids
      certification_requirement_id
      certification_requirement_ids
    ))
  end

  defp operator_training_qualification_values(row) do
    list_values(row, ~w(
      required_qualification_id
      required_qualification_ids
      required_operator_qualification_id
      required_operator_qualification_ids
      qualification_requirement_id
      qualification_requirement_ids
    ))
  end

  defp list_values(row, fields) do
    Enum.flat_map(fields, fn field -> list_value(Map.get(row, field)) end)
  end

  defp stable_sorted_evidence_values(values) do
    values
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_array_map(%{} = map) do
    map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      key = normalized_evidence_string(key)
      ids = values |> list_value() |> stable_sorted_evidence_values()

      if key && ids != [] do
        Map.put(acc, key, ids)
      else
        acc
      end
    end)
  end

  defp stable_id_array_map(_map), do: %{}

  defp merge_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = map, acc ->
        map
        |> stable_id_array_map()
        |> Enum.reduce(acc, fn {key, ids}, inner_acc ->
          Map.update(inner_acc, key, ids, fn current ->
            (current ++ ids)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)

      _map, acc ->
        acc
    end)
  end

  defp resource_availability_reason_counts(review_rows, import_rows) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(&resource_availability_reasons/1)
    |> Enum.frequencies()
  end

  defp resource_blocking_dimension_counts(review_rows, import_rows) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(&resource_blocking_dimensions/1)
    |> Enum.frequencies()
  end

  defp resource_blocked_contact_id_map(review_rows, import_rows, map_field, group_field) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.flat_map(fn row ->
      resource_blocked_contact_id_maps(row, map_field) ++
        [resource_blocked_contact_id_pair_map(row, group_field)]
    end)
    |> merge_string_list_maps()
  end

  defp resource_provenance_counts(review_rows, import_rows, field) do
    review_rows
    |> source_resource_evidence_rows(import_rows)
    |> Enum.map(&resource_provenance_map/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp source_resource_evidence_rows(review_rows, _import_rows) when review_rows != [],
    do: review_rows

  defp source_resource_evidence_rows(_review_rows, import_rows), do: import_rows

  defp resource_provenance_map(%{} = row) do
    [
      row["source_resource_projection"],
      get_in(row, ["source_review_row", "source_resource_projection"]),
      row["source_resource_suppression"],
      get_in(row, ["source_contact_allocation", "source_resource_suppression"]),
      get_in(row, ["source_review_row", "source_resource_suppression"]),
      get_in(row, [
        "source_review_row",
        "source_contact_allocation",
        "source_resource_suppression"
      ]),
      row["source_contact_allocation"],
      get_in(row, ["source_review_row", "source_contact_allocation"]),
      row,
      row["source_review_row"]
    ]
    |> Enum.find(&is_map/1)
  end

  defp resource_availability_reasons(row) do
    row
    |> resource_evidence_maps()
    |> Enum.flat_map(fn evidence ->
      list_value(evidence["resource_pressure_types"]) ++
        [
          evidence["first_resource_pressure_kind"],
          evidence["allocation_reason"],
          evidence["suppressed_reason"],
          evidence["resource_effect_reason"]
        ]
    end)
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&(&1 in resource_availability_reasons()))
    |> Enum.uniq()
  end

  defp resource_blocking_dimensions(row) do
    row
    |> resource_evidence_maps()
    |> Enum.map(&Map.get(&1, "resource_blocking_dimension"))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp resource_blocked_contact_id_maps(%{} = row, field) do
    [row, row["source_review_row"]]
    |> Enum.map(fn
      %{} = evidence -> Map.get(evidence, field)
      _evidence -> nil
    end)
    |> Enum.filter(&is_map/1)
  end

  defp resource_blocked_contact_id_maps(_row, _field), do: []

  defp resource_blocked_contact_id_pair_map(row, group_field) do
    row
    |> resource_evidence_maps()
    |> Enum.reduce(%{}, fn evidence, acc ->
      group = evidence |> Map.get(group_field) |> normalized_evidence_string()
      contact_id = resource_blocked_contact_id(evidence)

      if group && contact_id do
        Map.update(acc, group, [contact_id], &[contact_id | &1])
      else
        acc
      end
    end)
    |> stable_id_array_map()
  end

  defp resource_blocked_contact_id(%{} = evidence) do
    [
      evidence["contact_id"],
      evidence["activity_id"],
      evidence["candidate_activity_id"],
      evidence["id"]
    ]
    |> Enum.find_value(&normalized_evidence_string/1)
  end

  defp resource_evidence_maps(%{} = row) do
    [
      row,
      row["source_review_row"],
      row["source_resource_projection"],
      row["source_resource_suppression"],
      get_in(row, ["source_contact_allocation", "source_resource_suppression"]),
      row["source_contact_allocation"],
      row["source_contact_suppression"],
      get_in(row, ["source_review_row", "source_resource_projection"]),
      get_in(row, ["source_review_row", "source_resource_suppression"]),
      get_in(row, [
        "source_review_row",
        "source_contact_allocation",
        "source_resource_suppression"
      ]),
      get_in(row, ["source_review_row", "source_contact_allocation"]),
      get_in(row, ["source_review_row", "source_contact_suppression"])
    ]
    |> Enum.filter(&is_map/1)
  end

  defp resource_evidence_maps(_row), do: []

  defp resource_availability_reasons do
    ~w(
      antenna_unavailable
      activity_type_incompatible_with_resource_summary
      activity_type_suppressed_by_resource_summary
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp adapter_boundary_status_counts(artifact, review_rows, import_rows) do
    (artifact_adapter_boundary_statuses(artifact) ++
       row_adapter_boundary_statuses(review_rows) ++ row_adapter_boundary_statuses(import_rows))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_adapter_boundary_statuses(%{} = artifact) do
    cond do
      adapter_boundary_context?(artifact) -> [adapter_boundary_status(artifact)]
      true -> []
    end
  end

  defp artifact_adapter_boundary_statuses(_artifact), do: []

  defp row_adapter_boundary_statuses(rows) do
    rows
    |> Enum.filter(&adapter_boundary_context?/1)
    |> Enum.map(&adapter_boundary_status/1)
  end

  defp adapter_boundary_context?(%{} = value) do
    direct_keys = ~w(
      provider
      adapter
      adapter_version
      import_adapter
      cadence_import_adapter
      cadence_import_adapter_version
      external_id
    )

    nested_values =
      [
        get_in(value, ["cadence_import", "provider"]),
        get_in(value, ["cadence_import", "adapter"]),
        get_in(value, ["cadence_import", "adapter_version"]),
        get_in(value, ["cadence_import", "external_id"]),
        get_in(value, ["source_review_row", "provider"]),
        get_in(value, ["source_review_row", "adapter"]),
        get_in(value, ["source_review_row", "adapter_version"]),
        get_in(value, ["source_review_row", "import_adapter"]),
        get_in(value, ["source_review_row", "cadence_import_adapter"]),
        get_in(value, ["source_review_row", "cadence_import_adapter_version"]),
        get_in(value, ["source_review_row", "cadence_import", "provider"]),
        get_in(value, ["source_review_row", "cadence_import", "adapter"]),
        get_in(value, ["source_review_row", "cadence_import", "adapter_version"]),
        get_in(value, ["source_review_row", "cadence_import", "external_id"])
      ]

    Enum.any?(direct_keys, &nonempty_string?(Map.get(value, &1))) or
      Enum.any?(nested_values, &nonempty_string?/1)
  end

  defp adapter_boundary_context?(_value), do: false

  defp adapter_boundary_status(%{} = value) do
    boundaries = adapter_trust_boundary_values(value)

    cond do
      boundaries == [] ->
        "missing"

      Enum.all?(boundaries, &adapter_missing_trust_boundary?/1) ->
        "missing"

      Enum.any?(boundaries, &adapter_untrusted_trust_boundary?/1) ->
        "untrusted"

      true ->
        "declared"
    end
  end

  defp adapter_trust_boundary_values(%{} = value) do
    [
      value["trust_boundary"],
      value["cadence_import_trust_boundary"],
      get_in(value, ["provenance", "trust_boundary"]),
      get_in(value, ["cadence_import", "trust_boundary"]),
      get_in(value, ["cadence_import", "provenance", "trust_boundary"]),
      get_in(value, ["source_review_row", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import_trust_boundary"]),
      get_in(value, ["source_review_row", "provenance", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import", "provenance", "trust_boundary"])
    ]
    |> Enum.filter(&nonempty_string?/1)
  end

  defp nonempty_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp nonempty_string?(_value), do: false

  defp adapter_missing_trust_boundary?(value) do
    normalized_trust_boundary_token(value) in ~w(missing none nil null undefined undeclared not_declared)
  end

  defp adapter_untrusted_trust_boundary?(value) do
    token = normalized_trust_boundary_token(value)

    token in ~w(unknown untrusted unverified unauthenticated unsigned rejected invalid not_trusted) or
      String.contains?(token, "untrusted") or
      String.contains?(token, "unknown") or
      String.contains?(token, "unverified") or
      String.contains?(token, "unauthenticated") or
      String.contains?(token, "not_trusted")
  end

  defp normalized_trust_boundary_token(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp count_values(counts, values) do
    values
    |> Enum.map(&Map.get(counts, &1, 0))
    |> Enum.sum()
  end

  defp import_classification(gates) do
    statuses = Enum.map(gates, & &1["status"])

    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      true -> "importable"
    end
  end

  defp readiness_level("importable"), do: "import_eligible"
  defp readiness_level("review_only"), do: "operator_review"
  defp readiness_level("analysis_only"), do: "analysis_only"
  defp readiness_level("blocked"), do: "blocked"

  defp report_status("importable"), do: "passed"
  defp report_status("review_only"), do: "review_required"
  defp report_status("analysis_only"), do: "analysis_only"
  defp report_status("blocked"), do: "blocked"

  defp gate_count(gates, status), do: Enum.count(gates, &(&1["status"] == status))

  defp analysis_only_decision(artifact, opts) do
    cond do
      Keyword.get(opts, :not_for_execution) == true ->
        {"not_for_execution", "opts.not_for_execution",
         "opts mark the artifact not-for-execution"}

      mode = opts |> Keyword.get(:mode) |> normalized_mode() ->
        analysis_mode_decision(mode, "opts.mode")

      mode = opts |> Keyword.get(:operational_mode) |> normalized_mode() ->
        analysis_mode_decision(mode, "opts.operational_mode")

      truthy?(Map.get(artifact, "not_for_execution")) ->
        {"not_for_execution", "artifact.not_for_execution",
         "artifact is marked not-for-execution"}

      truthy?(get_in(artifact, ["metadata", "not_for_execution"])) ->
        {"not_for_execution", "artifact.metadata.not_for_execution",
         "artifact metadata marks the artifact not-for-execution"}

      truthy?(get_in(artifact, ["assumptions", "not_for_execution"])) ->
        {"not_for_execution", "artifact.assumptions.not_for_execution",
         "artifact assumptions mark the artifact not-for-execution"}

      mode =
          artifact
          |> first_value([
            ["operational_mode"],
            ["mode"],
            ["artifact_mode"],
            ["metadata", "operational_mode"],
            ["metadata", "mode"],
            ["assumptions", "operational_mode"],
            ["assumptions", "mode"]
          ])
          |> normalized_mode() ->
        analysis_mode_decision(mode, "artifact mode")

      true ->
        nil
    end
  end

  defp analysis_mode_decision(mode, source) when mode in @analysis_modes do
    {mode, source, "#{source} marks the artifact #{mode}"}
  end

  defp analysis_mode_decision(_mode, _source), do: nil

  defp normalized_mode(nil), do: nil

  defp normalized_mode(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> nil
      value -> Map.get(@analysis_mode_aliases, value, value)
    end
  end

  defp truthy?(value) when value in [true, "true", "yes", "1", 1], do: true
  defp truthy?(value) when is_binary(value), do: normalized_mode(value) in ["true", "yes", "1"]
  defp truthy?(value) when is_atom(value), do: value |> Atom.to_string() |> truthy?()
  defp truthy?(_value), do: false

  defp first_value(map, paths) do
    paths
    |> Enum.map(&get_in(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp source_artifact_type(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_type"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_type"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_type"] || artifact["schema_contract"]

      is_map(review_package) ->
        review_package["source_artifact_type"] || artifact["schema_contract"]

      true ->
        artifact["schema_contract"]
    end
  end

  defp source_artifact_id(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_id"] || artifact["manifest_id"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_id"] || artifact["package_id"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      is_map(review_package) ->
        review_package["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      true ->
        artifact["id"] || artifact["report_id"]
    end
  end

  defp report_id(source_artifact_type, source_artifact_id) do
    ["operational_readiness", source_artifact_type, source_artifact_id || "unknown"]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unknown"
      fragment -> fragment
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
