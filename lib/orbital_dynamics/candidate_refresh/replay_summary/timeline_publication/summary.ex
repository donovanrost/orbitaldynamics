defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.Summary do
  @moduledoc false

  alias __MODULE__.PublicationFields
  alias __MODULE__.Pressure

  def summary(publication_summary, summary_source, replay_scope) do
    row_count = summary_integer(publication_summary, "row_count")

    dependency_impact_row_count =
      summary_integer(publication_summary, "dependency_impact_row_count")

    timeline_diff_row_count = summary_integer(publication_summary, "timeline_diff_row_count")

    timeline_diff_changed_count =
      summary_integer(publication_summary, "timeline_diff_changed_count")

    timeline_diff_review_required_count =
      summary_integer(publication_summary, "timeline_diff_review_required_count")

    publication_fields = PublicationFields.fields(publication_summary)

    pressure_fields =
      Pressure.fields(
        publication_fields,
        row_count,
        dependency_impact_row_count,
        timeline_diff_row_count,
        timeline_diff_changed_count,
        timeline_diff_review_required_count
      )

    %{
      "model" => "artifact_only_candidate_refresh_timeline_publication_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          publication_summary,
          "timeline_publication_summary.v1"
        ),
      "source_report_count" => summary_integer(publication_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(publication_summary, "paths", []),
      "source_summary_model_counts" =>
        Map.get(publication_summary, "source_summary_model_counts", %{}),
      "source_summary_schema_contract_counts" =>
        Map.get(publication_summary, "source_summary_schema_contract_counts", %{}),
      "dependency_impact_row_count" => dependency_impact_row_count,
      "timeline_diff_row_count" => timeline_diff_row_count,
      "timeline_diff_changed_count" => timeline_diff_changed_count,
      "timeline_diff_review_required_count" => timeline_diff_review_required_count,
      "trust_boundary_status" => Map.get(publication_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(publication_summary, "trust_boundaries", []),
      "branch_local_timeline_publication_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_publication_pressure"),
      "branch_local_timeline_publication_dependency_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_publication_dependency_pressure"),
      "branch_local_timeline_publication_changed_field_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_publication_changed_field_pressure"),
      "branch_local_timeline_publication_invalidation_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_publication_invalidation_pressure"),
      "branch_local_timeline_publication_review_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_publication_review_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "publication_execution" => "not_performed_by_summary",
        "notification_delivery" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_timeline_publication_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_publication_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(publication_fields)
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
