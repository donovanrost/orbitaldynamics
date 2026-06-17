defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Aggregation do
  @moduledoc false

  alias __MODULE__.Values

  def source_report_family_count(source_reports, family, field) do
    if Map.has_key?(source_reports, family) do
      source_reports
      |> Map.take([family])
      |> Map.values()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  def source_report_family_count_or_zero(source_reports, family, field) do
    source_report_family_count(source_reports, family, field) || 0
  end

  def source_report_family_identity_count(source_reports, family, field) do
    if source_report_family_has_identity_counts?(source_reports, family) do
      source_report_family_count(source_reports, family, field)
    end
  end

  def source_report_family_field(source_reports, family, field) do
    source_reports
    |> Map.get(family, %{})
    |> Map.get(field)
  end

  def source_report_family_merge_count_maps(source_reports, family, field) do
    source_reports
    |> Map.take([family])
    |> Map.values()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  def source_report_objective_gap_contracts(source_reports) do
    source_reports
    |> source_report_objective_gap_family_values("contract")
    |> Values.sorted_string_values()
  end

  def source_report_objective_gap_identity_paths(source_reports) do
    complete_families =
      source_reports
      |> source_report_objective_gap_families()
      |> Enum.filter(&source_report_family_has_identity_counts?(source_reports, &1))

    if Enum.any?(
         complete_families,
         &(source_reports |> Map.get(&1, %{}) |> Map.has_key?("paths"))
       ) do
      paths =
        complete_families
        |> Enum.flat_map(fn family ->
          source_reports
          |> source_report_family_field(family, "paths")
          |> List.wrap()
        end)
        |> Values.sorted_string_values()

      if paths != [] or
           Enum.any?(
             complete_families,
             &(source_reports |> Map.get(&1, %{}) |> Map.get("paths") == [])
           ) do
        paths
      end
    end
  end

  def source_report_objective_gap_identity_count(source_reports, field) do
    source_reports
    |> source_report_objective_gap_families()
    |> Enum.map(&source_report_family_identity_count(source_reports, &1, field))
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      counts -> Enum.sum(counts)
    end
  end

  def source_report_objective_gap_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_objective_gap_families()
    |> Enum.map(&source_report_family_merge_count_maps(source_reports, &1, field))
    |> Values.merge_count_maps()
  end

  defp source_report_family_has_identity_counts?(source_reports, family) do
    case Map.get(source_reports, family) do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_objective_gap_family_values(source_reports, field) do
    source_reports
    |> source_report_objective_gap_families()
    |> Enum.map(&source_report_family_field(source_reports, &1, field))
    |> Enum.reject(&is_nil/1)
  end

  defp source_report_objective_gap_families(_source_reports) do
    [
      "objective_satisfaction_report",
      "objective_tradeoff_report",
      "score_term_report"
    ]
  end
end
