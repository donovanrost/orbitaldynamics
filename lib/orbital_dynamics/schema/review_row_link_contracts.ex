defmodule OrbitalDynamics.Schema.ReviewRowLinkContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.StableIdValidation

  def validate(issues, path, row) do
    issues
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "source_window_lineage",
      "candidate_activity_id",
      "activity_id",
      "must match activity_id"
    )
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "source_window_lineage",
      "source_window_id",
      "source_window_id",
      "must match source_window_id"
    )
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "replacement_source_window",
      "id",
      "replacement_source_window_id",
      "must match replacement_source_window_id"
    )
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "replacement_source_window_lineage",
      "candidate_activity_id",
      "replacement_candidate_id",
      "must match replacement_candidate_id"
    )
    |> StableIdValidation.validate_nested_id_match(
      path,
      row,
      "replacement_source_window_lineage",
      "source_window_id",
      "replacement_source_window_id",
      "must match replacement_source_window_id"
    )
  end
end
