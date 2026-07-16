defmodule OrbitalDynamics.Schema.TimelineIdentityCollisionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_optional_non_negative_integer: 4, expect_optional_type: 5]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4]

  def validate_fields(issues, path, row) do
    issues
    |> expect_optional_type(path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(path, row, "duplicate_timeline_identity_scope", :binary)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "source_duplicate_activity_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "replacement_duplicate_activity_count"
    )
    |> expect_optional_type(path, row, "source_duplicate_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "source_duplicate_activity_ids")
    |> expect_optional_type(path, row, "replacement_duplicate_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "replacement_duplicate_activity_ids"
    )
    |> expect_optional_type(path, row, "source_duplicate_activities", :list)
    |> expect_optional_type(path, row, "replacement_duplicate_activities", :list)
  end
end
