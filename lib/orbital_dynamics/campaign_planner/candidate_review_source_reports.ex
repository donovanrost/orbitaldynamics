defmodule OrbitalDynamics.CampaignPlanner.CandidateReviewSourceReports do
  @moduledoc false

  def candidate_diff_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_candidate_diff_report", "mission_state.source_candidate_diff_report"},
        {"candidate_diff_report", "mission_state.candidate_diff_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_candidate_diff_report", opts) ++
      result_artifact_embedded_reports(mission_state, "candidate_diff_report", opts)
  end

  def source_candidate_diff_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_candidate_diff_report", "mission_state.source_candidate_diff_report"}
      ],
      opts
    )
  end

  def canonical_candidate_diff_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"candidate_diff_report", "mission_state.candidate_diff_report"}
      ],
      opts
    )
  end

  def candidate_rejection_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_candidate_rejection_report", "mission_state.source_candidate_rejection_report"},
        {"candidate_rejection_report", "mission_state.candidate_rejection_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_candidate_rejection_report", opts) ++
      result_artifact_embedded_reports(mission_state, "candidate_rejection_report", opts)
  end

  def source_candidate_rejection_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_candidate_rejection_report", "mission_state.source_candidate_rejection_report"}
      ],
      opts
    )
  end

  def canonical_candidate_rejection_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"candidate_rejection_report", "mission_state.candidate_rejection_report"}
      ],
      opts
    )
  end

  def candidate_diff_pressure_rows(reports) do
    report_pressure_rows(
      reports,
      &candidate_diff_replacement_rows/1,
      fn source_path -> "#{source_path}.invalidated_candidates" end
    )
  end

  def candidate_rejection_pressure_rows(reports) do
    report_pressure_rows(
      reports,
      fn report ->
        report
        |> Map.get("rows", [])
        |> List.wrap()
      end,
      fn source_path -> "#{source_path}.rows" end
    )
  end

  def candidate_diff_replacement_rows(report) do
    report
    |> Map.get("invalidated_candidates", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&is_binary(Map.get(&1, "replacement_candidate_id")))
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp report_pressure_rows(reports, rows_fun, source_path_fun) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> rows_fun.()
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {
          Map.put(row, "_source_report_trust_boundary", trust_boundary),
          source_path_fun.(source_path),
          index
        }
      end)
    end)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
