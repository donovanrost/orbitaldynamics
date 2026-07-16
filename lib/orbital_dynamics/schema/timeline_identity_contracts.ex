defmodule OrbitalDynamics.Schema.TimelineIdentityContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation

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

  def validate_optional_identity(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = identity -> validate_identity(issues, "#{path}.#{field}", identity)
      _value -> issues
    end
  end

  def validate_identity(issues, path, identity) when is_map(identity) do
    issues
    |> StableIdValidation.validate_stable_ids(path, identity, @identity_stable_id_fields)
    |> PrimitiveValidation.expect_optional_type(path, identity, "activity_type", :binary)
    |> PrimitiveValidation.expect_optional_type(path, identity, "subject_id", :binary)
    |> PrimitiveValidation.expect_optional_type(path, identity, "source", :binary)
  end

  def validate_identity(issues, _path, _identity), do: issues

  def validate_optional_link(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = link -> validate_link(issues, "#{path}.#{field}", link)
      _value -> issues
    end
  end

  def validate_link(issues, path, link) do
    issues
    |> StableIdValidation.validate_stable_ids(path, link, @link_stable_id_fields)
    |> PrimitiveValidation.expect_optional_type(
      path,
      link,
      "source_invalid_activity_input",
      :boolean
    )
    |> PrimitiveValidation.expect_optional_type(
      path,
      link,
      "source_invalid_activity_input_reason",
      :binary
    )
    |> PrimitiveValidation.expect_optional_type(path, link, "source_activity", :map)
    |> PrimitiveValidation.expect_optional_type(path, link, "source_timeline_identity", :map)
    |> validate_optional_identity(path, link, "source_timeline_identity")
    |> PrimitiveValidation.expect_optional_type(
      path,
      link,
      "replacement_invalid_activity_input",
      :boolean
    )
    |> PrimitiveValidation.expect_optional_type(
      path,
      link,
      "replacement_invalid_activity_input_reason",
      :binary
    )
    |> PrimitiveValidation.expect_optional_type(path, link, "replacement_activity", :map)
    |> PrimitiveValidation.expect_optional_type(
      path,
      link,
      "replacement_timeline_identity",
      :map
    )
    |> validate_optional_identity(path, link, "replacement_timeline_identity")
  end
end
