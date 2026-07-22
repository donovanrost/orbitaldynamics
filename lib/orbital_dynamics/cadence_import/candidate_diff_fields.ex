defmodule OrbitalDynamics.CadenceImport.CandidateDiffFields do
  @moduledoc false

  def derive(row) do
    row
    |> Map.get("candidate_diff_changed_fields", Map.get(row, "changed_fields"))
    |> List.wrap()
    |> Enum.concat(semantic_change_detail_fields(row["semantic_change_details"]))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def count([]), do: nil
  def count(fields), do: length(fields)

  def reconcile_semantic_change_reasons(%{"semantic_change_details" => details} = row)
      when is_list(details) and details != [] do
    reasons =
      details
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "reason"))
      |> Enum.filter(&is_binary/1)

    Map.put(row, "semantic_change_reasons", reasons)
  end

  def reconcile_semantic_change_reasons(%{"semantic_change_details" => []} = row) do
    Map.delete(row, "semantic_change_details")
  end

  def reconcile_semantic_change_reasons(row), do: row

  defp semantic_change_detail_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
  end
end
