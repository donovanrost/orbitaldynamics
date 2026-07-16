defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CandidateDiff do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    rows =
      [
        Map.get(report, "retained_candidates") || Map.get(report, :retained_candidates),
        Map.get(report, "new_candidates") || Map.get(report, :new_candidates),
        Map.get(report, "invalidated_candidates") || Map.get(report, :invalidated_candidates)
      ]

    Enum.any?(rows, &is_list/1) and schema_contract in [nil, "candidate_diff_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
