defmodule OrbitalDynamics.Schema.TimelineIdentityCollisionContracts do
  @moduledoc false

  def validate_fields(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(callbacks, path, row, "duplicate_timeline_identity_scope", :binary)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "source_duplicate_activity_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "replacement_duplicate_activity_count"
    )
    |> expect_optional_type(callbacks, path, row, "source_duplicate_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "source_duplicate_activity_ids")
    |> expect_optional_type(callbacks, path, row, "replacement_duplicate_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "replacement_duplicate_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "source_duplicate_activities", :list)
    |> expect_optional_type(callbacks, path, row, "replacement_duplicate_activities", :list)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, row, field)
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, row, field, type)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, row, field)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
