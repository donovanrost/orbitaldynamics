defmodule OrbitalDynamics.Timeline.DiffFieldSelectionPolicy do
  @moduledoc false

  def changed_fields(
        source,
        replacement,
        diff_compare_fields,
        activity_context_compare_fields
      ) do
    diff_compare_fields
    |> Enum.filter(
      &(compare_value(source, &1, activity_context_compare_fields) !=
          compare_value(replacement, &1, activity_context_compare_fields))
    )
  end

  def review_significant_change?(changed_fields, diff_compare_fields) do
    Enum.any?(changed_fields, &(&1 in diff_compare_fields))
  end

  defp compare_value(row, field, activity_context_compare_fields) do
    if field in activity_context_compare_fields do
      case Map.fetch(row, field) do
        {:ok, nil} -> get_in(row, ["activity_context", field])
        {:ok, value} -> value
        :error -> get_in(row, ["activity_context", field])
      end
    else
      Map.get(row, field)
    end
  end
end
