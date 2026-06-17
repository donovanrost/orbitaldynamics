defmodule OrbitalDynamics.CampaignPlanner.ModelAcceptanceSourceReports do
  @moduledoc false

  def model_acceptance_reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(
      mission_state,
      [
        {"source_model_acceptance_report", "mission_state.source_model_acceptance_report"},
        {"model_acceptance_report", "mission_state.model_acceptance_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_model_acceptance_report", opts) ++
      result_artifact_embedded_reports(mission_state, "model_acceptance_report", opts)
  end

  def model_acceptance_reports(mission_state, "source_model_acceptance_report", opts) do
    source_model_acceptance_reports(mission_state, opts)
  end

  def model_acceptance_reports(mission_state, "model_acceptance_report", opts) do
    canonical_model_acceptance_reports(mission_state, opts)
  end

  def source_model_acceptance_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_model_acceptance_report", "mission_state.source_model_acceptance_report"}
      ],
      opts
    )
  end

  def canonical_model_acceptance_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"model_acceptance_report", "mission_state.model_acceptance_report"}
      ],
      opts
    )
  end

  def pressure_rows(reports) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> report_pressure_rows()
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row_source =
          row
          |> Map.get("source", "model_acceptance_report")
          |> String.replace_prefix("model_acceptance_report", source_path)

        row =
          row
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, row_source, index}
      end)
    end)
  end

  defp report_pressure_rows(report) do
    report = stringify_keys(report || %{})

    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      %{
        "source" => "model_acceptance_report.rows",
        "report_id" => report["report_id"],
        "intended_use" => report["intended_use"],
        "model_acceptance_status" => report["status"],
        "model_count" => report["model_count"],
        "accepted_count" => report["accepted_count"],
        "review_required_count" => report["review_required_count"],
        "blocked_count" => report["blocked_count"],
        "unknown_model_count" => report["unknown_model_count"],
        "status_counts" => report["status_counts"],
        "validation_level_counts" => report["validation_level_counts"],
        "model_ids_by_status" => report["model_ids_by_status"],
        "model_ids_by_validation_level" => report["model_ids_by_validation_level"],
        "model_ids_by_intended_use" => report["model_ids_by_intended_use"],
        "model_id" => row["model_id"],
        "validation_level" => row["validation_level"],
        "model_status" => row["status"],
        "model_reason" => row["reason"],
        "source_model_acceptance_row" => row,
        "source_model_acceptance_report" => report
      }
      |> compact_map()
    end)
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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

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
