defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Selection
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Summary

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Summary.StateFields
  alias __MODULE__.Pressure

  def source_report_fields(
        refresh_or_artifact,
        source_reports,
        family,
        contract,
        source_model
      ) do
    summary =
      selected_source_report_summary(
        refresh_or_artifact,
        source_reports,
        contract,
        source_model
      )

    source_report_fields(family, summary || %{})
  end

  def source_report_fields(family, state_summary) do
    prefix = "source_report_#{family}"

    state_fields =
      StateFields.fields(
        state_summary,
        source_summary_empty: :preserve,
        action_routing_nil: :preserve
      )

    %{
      "#{prefix}_contract" => source_report_summary_contract(state_summary, nil),
      "#{prefix}_count" => summary_integer(state_summary, "count"),
      "#{prefix}_row_count" => summary_integer(state_summary, "row_count"),
      "#{prefix}_paths" => Map.get(state_summary, "paths", []),
      "#{prefix}_review_required_count" =>
        summary_integer(state_summary, "review_required_count"),
      "#{prefix}_invalid_activity_input_count" =>
        summary_integer(state_summary, "invalid_activity_input_count")
    }
    |> Map.merge(prefix_fields(prefix, state_fields))
  end

  def source_report_pressure_fields(
        refresh_or_artifact,
        source_reports,
        family,
        contract,
        source_model,
        application_boundary,
        authority_boundary
      ) do
    selected_summary =
      refresh_or_artifact
      |> selected_source_report_summary(
        source_reports,
        contract,
        source_model
      )

    summary =
      (selected_summary || %{})
      |> Summary.summary(
        family,
        "candidate_refresh.source_report_provenance.#{family}",
        "#{family}_source_report_provenance_only",
        application_boundary,
        authority_boundary
      )

    Pressure.source_report_fields(family, summary)
  end

  defp prefix_fields(prefix, fields) do
    fields
    |> Enum.map(fn {field, value} -> {"#{prefix}_#{field}", value} end)
    |> Map.new()
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

  defp selected_source_report_summary(
         refresh_or_artifact,
         source_reports,
         contract,
         source_model
       ) do
    Selection.selected_source_report_summary(
      refresh_or_artifact,
      source_reports,
      contract,
      source_model
    )
  end
end
