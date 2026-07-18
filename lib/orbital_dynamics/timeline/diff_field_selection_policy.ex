defmodule OrbitalDynamics.Timeline.DiffFieldSelectionPolicy do
  @moduledoc false

  def changed_fields(source, replacement, diff_compare_fields, diff_compare_value) do
    diff_compare_fields
    |> Enum.filter(&(diff_compare_value.(source, &1) != diff_compare_value.(replacement, &1)))
  end

  def review_significant_change?(changed_fields, diff_compare_fields) do
    Enum.any?(changed_fields, &(&1 in diff_compare_fields))
  end
end
