defmodule OrbitalDynamics.Schema.ReviewRowLinkContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "source_window_lineage",
      "candidate_activity_id",
      "activity_id",
      "must match activity_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "source_window_lineage",
      "source_window_id",
      "source_window_id",
      "must match source_window_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "replacement_source_window",
      "id",
      "replacement_source_window_id",
      "must match replacement_source_window_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "replacement_source_window_lineage",
      "candidate_activity_id",
      "replacement_candidate_id",
      "must match replacement_candidate_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "replacement_source_window_lineage",
      "source_window_id",
      "replacement_source_window_id",
      "must match replacement_source_window_id"
    )
  end

  defp validate_nested_id_match(
         issues,
         callbacks,
         path,
         row,
         nested_field,
         nested_id_field,
         expected_field,
         message
       ) do
    apply(require_callback(callbacks, :validate_nested_id_match), [
      issues,
      path,
      row,
      nested_field,
      nested_id_field,
      expected_field,
      message
    ])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
