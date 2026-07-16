defmodule OrbitalDynamics.CampaignPlanner.ContactIntentSourceReports.Rows do
  @moduledoc false

  def rows_with_source(container, source_prefix, source_keys, stringify_keys)
      when is_list(source_keys) and is_function(stringify_keys, 1) do
    container = stringify_keys.(container || %{})

    source_keys
    |> Enum.flat_map(fn key ->
      source_rows(Map.get(container, key), "#{source_prefix}.#{key}", stringify_keys)
    end)
  end

  defp source_rows(%{} = row, source_path, stringify_keys) do
    row
    |> stringify_keys.()
    |> row_with_source(source_path)
    |> List.wrap()
  end

  defp source_rows(rows, source_path, stringify_keys) when is_list(rows) do
    rows
    |> Enum.flat_map(&source_rows(&1, source_path, stringify_keys))
  end

  defp source_rows(_rows, _source_path, _stringify_keys), do: []

  defp row_with_source(row, source_path) do
    if standalone_row?(row) do
      {row, source_path}
    end
  end

  defp standalone_row?(%{"schema_contract" => "contact_intent.v1"}), do: true
  defp standalone_row?(_row), do: false
end
