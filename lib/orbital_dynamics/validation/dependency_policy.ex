defmodule OrbitalDynamics.Validation.DependencyPolicy do
  @moduledoc false

  def build do
    %{
      "policy_version" => 1,
      "required_dependencies" => [
        %{
          "package" => "nx",
          "version_requirement" => "~> 0.11",
          "reason" => "Nx-backed propagator modules compile unconditionally",
          "backend_modules" => [
            "OrbitalDynamics.Propagators.TwoBodyNx",
            "OrbitalDynamics.Propagators.TwoBodyNxCompiled"
          ]
        }
      ],
      "optional_dependencies" => [
        %{
          "package" => "exla",
          "version_requirement" => "~> 0.11",
          "reason" => "EXLA-backed propagator modules are experimental accelerator candidates",
          "backend_modules" => [
            "OrbitalDynamics.Propagators.TwoBodyExlaCpu",
            "OrbitalDynamics.Propagators.J2ExlaCpu"
          ]
        }
      ],
      "backend_acceptance_policy" => "backend_acceptance_policy.v1",
      "decisions" => [
        "do_not_mark_nx_optional_while_nx_modules_compile_unconditionally",
        "keep_exla_optional_until_exla_backends_are_default_or_required",
        "treat_nx_and_exla_backends_as_experimental_accelerators_until_benchmark_evidence_supports_a_workload_specific_claim"
      ]
    }
  end
end
