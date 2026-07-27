defmodule OrbitalDynamics.Schema.CampaignRepairHandoffValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def indexed_rows(rows, predicate) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} -> is_map(row) and predicate.(row) end)
  end

  def indexed_rows(_rows, _predicate), do: []

  def indexed_sources(values, prefix, suffix) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.map(fn {_value, index} -> "#{prefix}[#{index}].#{suffix}" end)
  end

  def indexed_sources(_values, _prefix, _suffix), do: []

  def row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  def validate_source_copies(
        issues,
        base_path,
        indexed_rows,
        source_rows,
        copy_paths,
        message
      ) do
    indexed_rows
    |> Enum.zip(source_rows)
    |> Enum.reduce(issues, fn {{row, row_index}, source_row}, acc ->
      Enum.reduce(copy_paths, acc, fn copy_path, inner_acc ->
        validate_optional_source_copy(
          inner_acc,
          base_path,
          row_index,
          row,
          copy_path,
          source_row,
          message
        )
      end)
    end)
  end

  def validate_source_identities(
        issues,
        base_path,
        indexed_rows,
        expected_sources,
        source_paths,
        message
      ) do
    indexed_rows
    |> Enum.zip(expected_sources)
    |> Enum.reduce(issues, fn {{row, row_index}, expected_source}, acc ->
      Enum.reduce(source_paths, acc, fn source_path, inner_acc ->
        case get_in(row, source_path) do
          source when is_binary(source) ->
            validate_equal(
              inner_acc,
              Enum.join([base_path <> "[#{row_index}]" | source_path], "."),
              source,
              expected_source,
              message
            )

          _source ->
            inner_acc
        end
      end)
    end)
  end

  def validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  def validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]

  defp validate_optional_source_copy(
         issues,
         base_path,
         row_index,
         row,
         copy_path,
         source_row,
         message
       ) do
    case get_in(row, copy_path) do
      %{} = copy ->
        validate_equal(
          issues,
          Enum.join([base_path <> "[#{row_index}]" | copy_path], "."),
          copy,
          source_row,
          message
        )

      _copy ->
        issues
    end
  end
end
