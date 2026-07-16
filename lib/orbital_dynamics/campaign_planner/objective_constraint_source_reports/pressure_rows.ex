defmodule OrbitalDynamics.CampaignPlanner.ObjectiveConstraintSourceReports.PressureRows do
  @moduledoc false

  def pressure_rows(reports) do
    report_pressure_rows(reports, &Map.get(&1, "rows", []))
  end

  def objective_tradeoff_pressure_rows(reports) do
    report_pressure_rows(reports, &objective_tradeoff_report_rows/1)
  end

  defp report_pressure_rows(reports, rows_fun) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> rows_fun.()
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {Map.put(row, "_source_report_trust_boundary", trust_boundary), source_path, index}
      end)
    end)
  end

  defp objective_tradeoff_report_rows(report) do
    cond do
      is_list(report["tradeoffs"]) -> report["tradeoffs"]
      is_list(report["rows"]) -> report["rows"]
      true -> []
    end
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
