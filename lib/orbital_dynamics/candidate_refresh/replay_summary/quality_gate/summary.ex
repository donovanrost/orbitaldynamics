defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary do
  @moduledoc false

  import __MODULE__.Values,
    only: [compact_map: 1, source_report_summary_contract: 2, summary_integer: 2]

  alias __MODULE__.Pressure
  alias __MODULE__.ResourceAvailabilityFields
  alias __MODULE__.RowIds

  def pressure_fields(quality_gate_summary) do
    Pressure.pressure_fields(quality_gate_summary)
  end

  def summary(
        quality_gate_summary,
        summary_source,
        replay_scope,
        timeline_publication_context
      ) do
    review_gate_count = summary_integer(quality_gate_summary, "review_gate_count")
    blocked_gate_count = summary_integer(quality_gate_summary, "blocked_gate_count")
    import_review_count = summary_integer(quality_gate_summary, "manifest_review_required_count")
    missing_import_count = summary_integer(quality_gate_summary, "missing_import_count")
    blocked_import_count = summary_integer(quality_gate_summary, "blocked_import_count")
    invalid_import_count = summary_integer(quality_gate_summary, "invalid_cadence_import_count")

    readiness_level_counts = Map.get(quality_gate_summary, "readiness_level_counts", %{})

    import_classification_counts =
      Map.get(quality_gate_summary, "import_classification_counts", %{})

    status_counts = Map.get(quality_gate_summary, "status_counts", %{})
    analysis_mode_counts = Map.get(quality_gate_summary, "analysis_mode_counts", %{})
    gate_status_counts = Map.get(quality_gate_summary, "gate_status_counts", %{})
    gate_classification_counts = Map.get(quality_gate_summary, "gate_classification_counts", %{})
    import_status_counts = Map.get(quality_gate_summary, "import_status_counts", %{})

    cadence_import_status_counts =
      Map.get(quality_gate_summary, "cadence_import_status_counts", %{})

    quality_gate_row_ids_by_status =
      Map.get(quality_gate_summary, "quality_gate_row_ids_by_status", %{})

    quality_gate_ids_by_status = Map.get(quality_gate_summary, "quality_gate_ids_by_status", %{})

    row_id_fields = RowIds.fields(quality_gate_summary)

    stale_or_unknown_freshness_quality_gate_row_ids =
      Map.get(quality_gate_summary, "stale_or_unknown_freshness_quality_gate_row_ids", [])

    import_preparation_quality_gate_row_ids =
      Map.get(quality_gate_summary, "import_preparation_quality_gate_row_ids", [])

    blocked_import_quality_gate_row_ids =
      Map.get(quality_gate_summary, "blocked_import_quality_gate_row_ids", [])

    import_readiness_gate_ids = Map.get(quality_gate_summary, "import_readiness_gate_ids", [])
    resource_availability_fields = ResourceAvailabilityFields.fields(quality_gate_summary)
    pressure_fields = Pressure.pressure_fields(quality_gate_summary, resource_availability_fields)

    %{
      "model" => "artifact_only_candidate_refresh_quality_gate_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(quality_gate_summary, "quality_gate_report.v1"),
      "source_report_count" => summary_integer(quality_gate_summary, "count"),
      "source_report_row_count" => summary_integer(quality_gate_summary, "row_count"),
      "source_report_paths" => Map.get(quality_gate_summary, "paths", []),
      "readiness_level_counts" => readiness_level_counts,
      "import_classification_counts" => import_classification_counts,
      "status_counts" => status_counts,
      "gate_count" => summary_integer(quality_gate_summary, "gate_count"),
      "passed_gate_count" => summary_integer(quality_gate_summary, "passed_gate_count"),
      "review_gate_count" => review_gate_count,
      "analysis_gate_count" => summary_integer(quality_gate_summary, "analysis_gate_count"),
      "analysis_mode_counts" => analysis_mode_counts,
      "blocked_gate_count" => blocked_gate_count,
      "gate_status_counts" => gate_status_counts,
      "gate_classification_counts" => gate_classification_counts,
      "non_passed_gate_count" => summary_integer(quality_gate_summary, "non_passed_gate_count"),
      "ready_for_import_count" => summary_integer(quality_gate_summary, "ready_for_import_count"),
      "manifest_review_required_count" => import_review_count,
      "blocked_import_count" => blocked_import_count,
      "missing_import_count" => missing_import_count,
      "invalid_cadence_import_count" => invalid_import_count,
      "freshness_status_counts" => Map.get(quality_gate_summary, "freshness_status_counts", %{}),
      "freshness_status_ids" => Map.get(quality_gate_summary, "freshness_status_ids", []),
      "schema_validation_status_counts" =>
        Map.get(quality_gate_summary, "schema_validation_status_counts", %{}),
      "schema_validation_status_ids" =>
        Map.get(quality_gate_summary, "schema_validation_status_ids", []),
      "failed_schema_validation_quality_gate_row_ids" =>
        Map.get(quality_gate_summary, "failed_schema_validation_quality_gate_row_ids", []),
      "schema_validation_gate_ids" =>
        Map.get(quality_gate_summary, "schema_validation_gate_ids", []),
      "operator_training_requirement_count" =>
        summary_integer(quality_gate_summary, "operator_training_requirement_count"),
      "operator_training_requirement_counts" =>
        Map.get(quality_gate_summary, "operator_training_requirement_counts", %{}),
      "operator_training_requirement_ids" =>
        Map.get(quality_gate_summary, "operator_training_requirement_ids", []),
      "required_operator_roles" => Map.get(quality_gate_summary, "required_operator_roles", []),
      "required_training_ids" => Map.get(quality_gate_summary, "required_training_ids", []),
      "required_certification_ids" =>
        Map.get(quality_gate_summary, "required_certification_ids", []),
      "required_qualification_ids" =>
        Map.get(quality_gate_summary, "required_qualification_ids", []),
      "review_only_quality_gate_row_ids" =>
        Map.get(quality_gate_summary, "review_only_quality_gate_row_ids", []),
      "operator_training_gate_ids" =>
        Map.get(quality_gate_summary, "operator_training_gate_ids", []),
      "import_status_counts" => import_status_counts,
      "import_status_ids" => Map.get(quality_gate_summary, "import_status_ids", []),
      "cadence_import_status_counts" => cadence_import_status_counts,
      "cadence_import_status_ids" =>
        Map.get(quality_gate_summary, "cadence_import_status_ids", []),
      "source_summary_model_counts" =>
        Map.get(quality_gate_summary, "source_summary_model_counts", %{}),
      "source_summary_schema_contract_counts" =>
        Map.get(quality_gate_summary, "source_summary_schema_contract_counts", %{}),
      "source_artifact_type_counts" =>
        Map.get(quality_gate_summary, "source_artifact_type_counts", %{}),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        Map.get(quality_gate_summary, "quality_gate_row_ids_by_classification", %{}),
      "quality_gate_ids_by_classification" =>
        Map.get(quality_gate_summary, "quality_gate_ids_by_classification", %{}),
      "passed_gate_ids" => Map.get(quality_gate_summary, "passed_gate_ids", []),
      "review_required_gate_ids" => Map.get(quality_gate_summary, "review_required_gate_ids", []),
      "analysis_only_gate_ids" => Map.get(quality_gate_summary, "analysis_only_gate_ids", []),
      "blocked_gate_ids" => Map.get(quality_gate_summary, "blocked_gate_ids", []),
      "non_passed_gate_ids" => Map.get(quality_gate_summary, "non_passed_gate_ids", []),
      "non_passed_quality_gate_row_ids" =>
        Map.get(quality_gate_summary, "non_passed_quality_gate_row_ids", []),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        stale_or_unknown_freshness_quality_gate_row_ids,
      "import_preparation_quality_gate_row_ids" => import_preparation_quality_gate_row_ids,
      "blocked_import_quality_gate_row_ids" => blocked_import_quality_gate_row_ids,
      "import_readiness_gate_ids" => import_readiness_gate_ids,
      "source_readiness_report_count" =>
        summary_integer(quality_gate_summary, "source_readiness_report_count"),
      "branch_local_review_pressure" => Map.get(pressure_fields, "branch_local_review_pressure"),
      "branch_local_import_pressure" => Map.get(pressure_fields, "branch_local_import_pressure"),
      "branch_local_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_quality_gate_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(resource_availability_fields)
    |> Map.merge(row_id_fields)
    |> Map.merge(timeline_publication_context)
    |> compact_map()
  end
end
