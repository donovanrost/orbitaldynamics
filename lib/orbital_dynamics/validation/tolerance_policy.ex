defmodule OrbitalDynamics.Validation.TolerancePolicy do
  @moduledoc false

  def build do
    %{
      "schema_contract" => "validation_tolerance_policy.v1",
      "comparison_model" => %{
        "numeric_scalars" =>
          "absolute error must be less than or equal to the fixture field tolerance",
        "numeric_vectors" =>
          "maximum component-wise absolute error must be less than or equal to the fixture field tolerance",
        "non_numeric_values" => "exact equality is required"
      },
      "event_timing" => %{
        "current_policy" => "sampled_state_linear_boundary",
        "event_time_tolerance_s" =>
          "default is maximum adjacent trajectory sample spacing; opt-in access bisection records the final cubic-Hermite interpolated-state root bracket",
        "confidence" =>
          "default is bounded_by_sample_cadence; opt-in access refinement is bounded_root_in_interpolated_state for each solved boundary",
        "limit" =>
          "linear interpolation does not justify a tighter claim; opt-in access roots narrow numerical placement only on the interpolated sample path and add no external-validation or flight-fidelity claim"
      },
      "artifact_regressions" => %{
        "scope" => "schema and public-surface stability checks for checked-in artifacts",
        "limit" => "not an external physics or operations truth model"
      },
      "validation_levels" => %{
        "assumption_declared" =>
          "assumption or environment capability is documented but not validated against a reference",
        "artifact_contract" =>
          "artifact structure and stable public fields are regression-tested",
        "educational" =>
          "suitable for examples and internal demonstrations inside the stated covered regime",
        "analysis" => "suitable for early trade studies inside stated assumptions and tolerances",
        "validated" =>
          "reserved for future external reference-tool or operational validation evidence"
      }
    }
  end
end
