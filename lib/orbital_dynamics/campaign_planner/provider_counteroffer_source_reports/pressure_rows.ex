defmodule OrbitalDynamics.CampaignPlanner.ProviderCounterofferSourceReports.PressureRows do
  @moduledoc false

  def pressure_rows(reports) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      {rows, row_source_path} = pressure_row_collection(report, source_path)

      rows
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {Map.put(row, "_source_report_trust_boundary", trust_boundary), row_source_path, index}
      end)
    end)
  end

  defp pressure_row_collection(%{"impact_rows" => rows}, source_path),
    do: {rows, "#{source_path}.impact_rows"}

  defp pressure_row_collection(%{"import_readiness_rows" => rows} = report, source_path) do
    rows =
      rows
      |> List.wrap()
      |> Enum.map(&import_readiness_pressure_row(&1, report))

    {rows, "#{source_path}.import_readiness_rows"}
  end

  defp pressure_row_collection(%{"rows" => rows}, source_path), do: {rows, "#{source_path}.rows"}
  defp pressure_row_collection(_report, source_path), do: {[], source_path}

  defp import_readiness_pressure_row(row, report) do
    row = stringify_keys(row)

    row
    |> put_new_present(
      "import_readiness_status",
      import_readiness_pressure_status(row, report)
    )
    |> put_new_present(
      "import_classification",
      import_readiness_pressure_classification(row, report)
    )
  end

  defp import_readiness_pressure_status(row, report) do
    cond do
      pressure_row_review_required?(row) -> "review_required"
      pressure_row_import_ready?(row) -> "import_ready"
      true -> report["import_readiness_status"]
    end
  end

  defp import_readiness_pressure_classification(row, report) do
    cond do
      pressure_row_review_required?(row) -> "review_only"
      pressure_row_import_ready?(row) -> "ready"
      true -> report["import_classification"]
    end
  end

  defp pressure_row_review_required?(row) do
    normalized_status_token(row["provider_counteroffer_import_status"]) ==
      "review_required_before_import" or
      normalized_status_token(row["required_operator_action"]) in [
        "review_provider_counteroffer",
        "review_required",
        "review_required_before_import"
      ] or row["reviewable"] == true
  end

  defp pressure_row_import_ready?(row) do
    normalized_status_token(row["provider_counteroffer_import_status"]) in [
      "import_ready",
      "no_import_required"
    ] or
      normalized_status_token(row["required_operator_action"]) in [
        "none",
        "no_import_required"
      ]
  end

  defp put_new_present(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_new_present(map, key, value) do
    case Map.get(map, key) do
      blank when blank in [nil, "", [], %{}] -> Map.put(map, key, value)
      _present -> map
    end
  end

  defp normalized_status_token(nil), do: nil

  defp normalized_status_token(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalized_status_token(status), do: status

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
