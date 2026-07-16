defmodule OrbitalDynamics.Schema.TimelineIdentityContracts do
  @moduledoc false

  @identity_stable_id_fields [
    "timeline_id",
    "activity_id",
    "scenario_id",
    "source_window_id"
  ]

  @link_stable_id_fields [
    "source_timeline_id",
    "source_activity_id",
    "replacement_timeline_id",
    "replacement_activity_id"
  ]

  def validate_optional_identity(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = identity -> validate_identity(issues, "#{path}.#{field}", identity, callbacks)
      _value -> issues
    end
  end

  def validate_identity(issues, path, identity, callbacks)
      when is_map(identity) and is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, identity, @identity_stable_id_fields)
    |> expect_optional_type(callbacks, path, identity, "activity_type", :binary)
    |> expect_optional_type(callbacks, path, identity, "subject_id", :binary)
    |> expect_optional_type(callbacks, path, identity, "source", :binary)
  end

  def validate_identity(issues, _path, _identity, _callbacks), do: issues

  def validate_optional_link(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = link -> validate_link(issues, "#{path}.#{field}", link, callbacks)
      _value -> issues
    end
  end

  def validate_link(issues, path, link, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, link, @link_stable_id_fields)
    |> expect_optional_type(callbacks, path, link, "source_invalid_activity_input", :boolean)
    |> expect_optional_type(
      callbacks,
      path,
      link,
      "source_invalid_activity_input_reason",
      :binary
    )
    |> expect_optional_type(callbacks, path, link, "source_activity", :map)
    |> expect_optional_type(callbacks, path, link, "source_timeline_identity", :map)
    |> validate_optional_identity(path, link, "source_timeline_identity", callbacks)
    |> expect_optional_type(callbacks, path, link, "replacement_invalid_activity_input", :boolean)
    |> expect_optional_type(
      callbacks,
      path,
      link,
      "replacement_invalid_activity_input_reason",
      :binary
    )
    |> expect_optional_type(callbacks, path, link, "replacement_activity", :map)
    |> expect_optional_type(callbacks, path, link, "replacement_timeline_identity", :map)
    |> validate_optional_identity(path, link, "replacement_timeline_identity", callbacks)
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
