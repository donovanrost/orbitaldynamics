defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.SourceRows
  alias __MODULE__.TransitionFields

  def summary(transition_summary, summary_source, replay_scope) do
    application_count = summary_integer(transition_summary, "application_count")
    selected_activity_count = summary_integer(transition_summary, "selected_activity_count")

    selected_integrity_review_count =
      summary_integer(transition_summary, "selected_timeline_integrity_review_count")

    selected_integrity_issue_count =
      summary_integer(transition_summary, "selected_timeline_integrity_issue_count")

    review_required_count = summary_integer(transition_summary, "review_required_count")
    preserved_source_count = summary_integer(transition_summary, "preserved_source_count")
    recorded_replacement_count = summary_integer(transition_summary, "recorded_replacement_count")
    withheld_review_count = summary_integer(transition_summary, "withheld_review_count")

    duplicate_count =
      summary_integer(transition_summary, "duplicate_timeline_identity_count")

    duplicate_source_count =
      summary_integer(transition_summary, "duplicate_source_timeline_identity_count")

    duplicate_replacement_count =
      summary_integer(transition_summary, "duplicate_replacement_timeline_identity_count")

    transition_fields = TransitionFields.fields(transition_summary)

    pressure_fields =
      Pressure.fields(transition_fields, %{
        application_count: application_count,
        selected_activity_count: selected_activity_count,
        selected_integrity_review_count: selected_integrity_review_count,
        selected_integrity_issue_count: selected_integrity_issue_count,
        review_required_count: review_required_count,
        preserved_source_count: preserved_source_count,
        recorded_replacement_count: recorded_replacement_count,
        withheld_review_count: withheld_review_count,
        duplicate_count: duplicate_count,
        duplicate_source_count: duplicate_source_count,
        duplicate_replacement_count: duplicate_replacement_count
      })

    %{
      "model" => "artifact_only_candidate_refresh_timeline_transition_application_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          transition_summary,
          "timeline_transition_application_report.v1"
        ),
      "source_report_count" => summary_integer(transition_summary, "count"),
      "source_report_row_count" => SourceRows.source_row_count(transition_summary),
      "source_application_count" => application_count,
      "source_report_paths" => Map.get(transition_summary, "paths", []),
      "selected_activity_count" => selected_activity_count,
      "selected_timeline_integrity_review_count" => selected_integrity_review_count,
      "selected_timeline_integrity_issue_count" => selected_integrity_issue_count,
      "review_required_count" => review_required_count,
      "preserved_source_count" => preserved_source_count,
      "recorded_replacement_count" => recorded_replacement_count,
      "withheld_review_count" => withheld_review_count,
      "duplicate_timeline_identity_count" => duplicate_count,
      "duplicate_source_timeline_identity_count" => duplicate_source_count,
      "duplicate_replacement_timeline_identity_count" => duplicate_replacement_count,
      "trust_boundary_status" => Map.get(transition_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(transition_summary, "trust_boundaries", []),
      "branch_local_timeline_transition_application_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_transition_application_pressure"),
      "branch_local_selected_activity_pressure" =>
        Map.get(pressure_fields, "branch_local_selected_activity_pressure"),
      "branch_local_selected_integrity_pressure" =>
        Map.get(pressure_fields, "branch_local_selected_integrity_pressure"),
      "branch_local_review_required_pressure" =>
        Map.get(pressure_fields, "branch_local_review_required_pressure"),
      "branch_local_preserved_transition_pressure" =>
        Map.get(pressure_fields, "branch_local_preserved_transition_pressure"),
      "branch_local_duplicate_identity_pressure" =>
        Map.get(pressure_fields, "branch_local_duplicate_identity_pressure"),
      "branch_local_operator_review_pressure" =>
        Map.get(pressure_fields, "branch_local_operator_review_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_transition_application_replay_summary",
        "timeline_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_transition_application_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(transition_fields)
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
