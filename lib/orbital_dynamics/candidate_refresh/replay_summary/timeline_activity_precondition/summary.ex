defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.Values

  def summary(precondition_summary, summary_source, replay_scope) do
    row_count = Values.summary_integer(precondition_summary, "row_count")

    blocked_precondition_count =
      Values.summary_integer(precondition_summary, "blocked_precondition_count")

    review_precondition_count =
      Values.summary_integer(precondition_summary, "review_precondition_count")

    invalid_activity_input_count =
      Values.summary_integer(precondition_summary, "invalid_activity_input_count")

    precondition_status_counts =
      Map.get(precondition_summary, "precondition_status_counts", %{})

    blocked_precondition_type_counts =
      Map.get(precondition_summary, "blocked_precondition_type_counts", %{})

    review_precondition_type_counts =
      Map.get(precondition_summary, "review_precondition_type_counts", %{})

    invalid_activity_input_reason_counts =
      Map.get(precondition_summary, "invalid_activity_input_reason_counts", %{})

    invalid_activity_input_reasons =
      Map.get(precondition_summary, "invalid_activity_input_reasons", [])

    activity_id_counts = Map.get(precondition_summary, "activity_id_counts", %{})
    timeline_id_counts = Map.get(precondition_summary, "timeline_id_counts", %{})

    dependency_activity_id_counts =
      Map.get(precondition_summary, "dependency_activity_id_counts", %{})

    dependency_timeline_id_counts =
      Map.get(precondition_summary, "dependency_timeline_id_counts", %{})

    exclusive_with_activity_id_counts =
      Map.get(precondition_summary, "exclusive_with_activity_id_counts", %{})

    exclusive_with_timeline_id_counts =
      Map.get(precondition_summary, "exclusive_with_timeline_id_counts", %{})

    duplicate_dependency_activity_id_counts =
      Map.get(precondition_summary, "duplicate_dependency_activity_id_counts", %{})

    duplicate_dependency_timeline_id_counts =
      Map.get(precondition_summary, "duplicate_dependency_timeline_id_counts", %{})

    duplicate_exclusivity_activity_id_counts =
      Map.get(precondition_summary, "duplicate_exclusivity_activity_id_counts", %{})

    duplicate_exclusivity_timeline_id_counts =
      Map.get(precondition_summary, "duplicate_exclusivity_timeline_id_counts", %{})

    allow_overlap_counts = Map.get(precondition_summary, "allow_overlap_counts", %{})

    source_summary_model_counts =
      precondition_summary
      |> Map.get("source_summary_model_counts", %{})
      |> Values.non_empty_map()

    source_summary_schema_contract_counts =
      Map.get(precondition_summary, "source_summary_schema_contract_counts", %{})
      |> Values.non_empty_map()

    pressure_fields =
      Pressure.fields(%{
        row_count: row_count,
        blocked_precondition_count: blocked_precondition_count,
        review_precondition_count: review_precondition_count,
        precondition_status_counts: precondition_status_counts,
        blocked_precondition_type_counts: blocked_precondition_type_counts,
        review_precondition_type_counts: review_precondition_type_counts,
        invalid_activity_input_count: invalid_activity_input_count,
        invalid_activity_input_reason_counts: invalid_activity_input_reason_counts,
        activity_id_counts: activity_id_counts,
        timeline_id_counts: timeline_id_counts,
        dependency_activity_id_counts: dependency_activity_id_counts,
        dependency_timeline_id_counts: dependency_timeline_id_counts,
        exclusive_with_activity_id_counts: exclusive_with_activity_id_counts,
        exclusive_with_timeline_id_counts: exclusive_with_timeline_id_counts,
        duplicate_dependency_activity_id_counts: duplicate_dependency_activity_id_counts,
        duplicate_dependency_timeline_id_counts: duplicate_dependency_timeline_id_counts,
        duplicate_exclusivity_activity_id_counts: duplicate_exclusivity_activity_id_counts,
        duplicate_exclusivity_timeline_id_counts: duplicate_exclusivity_timeline_id_counts,
        allow_overlap_counts: allow_overlap_counts
      })

    %{
      "model" => "artifact_only_candidate_refresh_timeline_activity_precondition_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          precondition_summary,
          "timeline_activity_precondition_summary.v1"
        ),
      "source_report_count" => Values.summary_integer(precondition_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(precondition_summary, "paths", []),
      "source_summary_model_counts" => source_summary_model_counts,
      "source_summary_schema_contract_counts" => source_summary_schema_contract_counts,
      "precondition_status_counts" => precondition_status_counts,
      "blocked_precondition_count" => blocked_precondition_count,
      "review_precondition_count" => review_precondition_count,
      "blocked_precondition_type_counts" => blocked_precondition_type_counts,
      "review_precondition_type_counts" => review_precondition_type_counts,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "invalid_activity_input_reason_counts" => invalid_activity_input_reason_counts,
      "invalid_activity_input_reasons" => invalid_activity_input_reasons,
      "activity_id_counts" => activity_id_counts,
      "timeline_id_counts" => timeline_id_counts,
      "dependency_activity_id_counts" => dependency_activity_id_counts,
      "dependency_timeline_id_counts" => dependency_timeline_id_counts,
      "exclusive_with_activity_id_counts" => exclusive_with_activity_id_counts,
      "exclusive_with_timeline_id_counts" => exclusive_with_timeline_id_counts,
      "duplicate_dependency_activity_id_counts" => duplicate_dependency_activity_id_counts,
      "duplicate_dependency_timeline_id_counts" => duplicate_dependency_timeline_id_counts,
      "duplicate_exclusivity_activity_id_counts" => duplicate_exclusivity_activity_id_counts,
      "duplicate_exclusivity_timeline_id_counts" => duplicate_exclusivity_timeline_id_counts,
      "allow_overlap_counts" => allow_overlap_counts,
      "trust_boundary_status" => Map.get(precondition_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(precondition_summary, "trust_boundaries", []),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_activity_precondition_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "activity_precondition_evaluation" => "not_performed_by_summary",
        "resource_authority" => "not_reserved_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_activity_precondition_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(pressure_fields)
    |> Values.compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil
end
