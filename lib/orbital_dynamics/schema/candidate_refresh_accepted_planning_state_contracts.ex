defmodule OrbitalDynamics.Schema.CandidateRefreshAcceptedPlanningStateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, %{} = accepted_state) do
    issues
    |> require_fields(path, accepted_state, ["snapshot_id", "spacecraft_state_count"])
    |> validate_stable_ids(path, accepted_state, ["snapshot_id"])
    |> expect_non_negative_integer(path, accepted_state, "spacecraft_state_count")
    |> expect_optional_type(path, accepted_state, "accepted_at", :binary)
    |> expect_optional_non_negative_integer(
      path,
      accepted_state,
      "maneuver_execution_delta_count"
    )
  end

  def validate(issues, _path, _accepted_state), do: issues
end
