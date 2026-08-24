defmodule OrbitalDynamics.Validation do
  @moduledoc """
  Validation-level registry for numerical models used in artifacts.

  The registry is evidence-oriented, not certification. It records the trust
  level, covered regime, tolerances, and known limits that current tests and
  benchmark fixtures support.
  """

  @model_acceptance_schema_contract "model_acceptance_report.v1"
  @safety_case_schema_contract "validation_safety_case_summary.v1"
  @schema_migration_schema_contract "schema_migration_report.v1"
  @model_acceptance_intended_uses [
    "demonstration",
    "analysis",
    "artifact_contract",
    "operational_import"
  ]
  @model_acceptance_statuses ["accepted_for_use", "review_required", "blocked"]
  @model_acceptance_row_statuses ["accepted", "review_required", "blocked"]
  @safety_case_statuses ["accepted_for_use", "review_required", "blocked", "missing_evidence"]
  @schema_migration_statuses ["current", "review_required"]
  @schema_migration_row_statuses ["current", "deprecated", "future"]
  @schema_migration_actions [
    "continue_current_contract",
    "plan_replacement",
    "prepare_future_contract",
    "review_deprecated_contract"
  ]
  @doc """
  Returns the validation capability vocabulary exposed by this module.
  """
  def capabilities do
    OrbitalDynamics.Validation.Capabilities.build(%{
      schema_contracts: [
        @model_acceptance_schema_contract,
        @safety_case_schema_contract,
        @schema_migration_schema_contract
      ],
      intended_uses: @model_acceptance_intended_uses,
      acceptance_statuses: @model_acceptance_statuses,
      row_statuses: @model_acceptance_row_statuses,
      safety_case_statuses: @safety_case_statuses,
      schema_migration_statuses: @schema_migration_statuses,
      schema_migration_row_statuses: @schema_migration_row_statuses,
      schema_migration_actions: @schema_migration_actions,
      tolerance_policy: &tolerance_policy/0
    })
  end

  @doc """
  Returns all registered validation records by stable ID.
  """
  def registry, do: OrbitalDynamics.Validation.Registry.all()

  @doc """
  Returns the project-wide validation tolerance policy.

  The policy is intentionally conservative: numeric fixture tolerances are
  absolute field-level bounds, sampled event detectors default to sample-cadence
  timing bounds, opt-in access roots are bounded only on their interpolated
  state path, and artifact fixtures are contract regressions rather than
  physics reference truth.
  """
  def tolerance_policy do
    OrbitalDynamics.Validation.TolerancePolicy.build()
  end

  @doc """
  Returns backend acceptance tiers for propagator implementations.

  The policy separates correctness comparison from performance claims. Scalar
  Elixir propagators remain the reference default; Nx/EXLA-style implementations
  are acceptable accelerator candidates only when they match reference outputs
  within the declared tolerance policy and have benchmark evidence for the
  workload shape being claimed.
  """
  def backend_acceptance_policy do
    OrbitalDynamics.Validation.BackendAcceptancePolicy.build()
  end

  @doc """
  Returns backend acceptance evidence for one propagator implementation.

  The returned map explains the backend tier and the evidence gates required
  before callers make correctness or performance claims for that implementation.
  """
  def backend_acceptance_evidence(implementation) do
    policy = backend_acceptance_policy()

    case OrbitalDynamics.Validation.ImplementationKey.normalize(implementation) do
      {:ok, implementation_name} ->
        backend_acceptance_evidence(policy, implementation_name)

      :error ->
        {:error, :invalid_backend_implementation}
    end
  end

  defp backend_acceptance_evidence(policy, implementation_name) do
    with {:ok, tier} <- Map.fetch(policy["implementation_tiers"], implementation_name),
         {:ok, acceptance_tier} <- Map.fetch(policy["acceptance_tiers"], tier) do
      {:ok,
       %{
         "backend_acceptance_policy" => "backend_acceptance_policy.v1",
         "implementation" => implementation_name,
         "tier" => tier,
         "reference_backend" => tier == policy["reference_backend"]["tier"],
         "requires_reference_match" =>
           Map.get(acceptance_tier, "requires_reference_match", false),
         "requires_benchmark_artifact" =>
           Map.get(acceptance_tier, "requires_benchmark_artifact", false),
         "requires_provider_policy" =>
           Map.get(acceptance_tier, "requires_provider_policy", false),
         "comparison_requirements" => policy["comparison_requirements"],
         "acceptance_tier" => acceptance_tier,
         "known_limits" => policy["known_limits"]
       }}
    else
      :error -> {:error, {:unknown_backend_implementation, implementation_name}}
    end
  end

  @doc """
  Returns the package/dependency policy for numerical backend modules.

  Nx is intentionally required while Nx-backed modules compile unconditionally.
  EXLA stays optional because EXLA-backed modules are experimental accelerator
  surfaces and not the reference planning backend.
  """
  def dependency_policy do
    OrbitalDynamics.Validation.DependencyPolicy.build()
  end

  @doc """
  Returns curated reference fixtures by stable ID.
  """
  def reference_fixtures, do: OrbitalDynamics.Validation.ReferenceFixtures.all()

  @doc """
  Fetches one validation record by stable ID or implementation module.
  """
  def record(id_or_module), do: OrbitalDynamics.Validation.Registry.fetch(id_or_module)

  defp implementation_name(implementation) do
    case OrbitalDynamics.Validation.ImplementationKey.normalize(implementation) do
      {:ok, name} -> name
      :error -> to_string(implementation)
    end
  end

  @doc """
  Builds a deterministic model-acceptance report for a declared intended use.

  The report classifies registry-backed model records as accepted, requiring
  review, or blocked. It is an artifact evidence summary, not certification.
  """
  def model_acceptance_report(models, opts \\ [])

  def model_acceptance_report(models, opts) when is_list(models) do
    OrbitalDynamics.Validation.ModelAcceptanceReport.build(models, opts, %{
      schema_contract: @model_acceptance_schema_contract,
      intended_uses: @model_acceptance_intended_uses,
      known_limits: capabilities().known_limits,
      record: &record/1,
      implementation_name: &implementation_name/1,
      tolerance_policy: &tolerance_policy/0
    })
  end

  def model_acceptance_report(model, opts), do: model_acceptance_report([model], opts)

  @doc """
  Builds an artifact-only safety-case summary from validation evidence.

  The summary is a routing aid, not certification. It preserves blocked and
  review-required evidence from model-acceptance, readiness, quality-gate,
  schema-validation, and fixture reports without granting import or operator
  authority.
  """
  def safety_case_summary(evidence, opts \\ []) do
    OrbitalDynamics.Validation.SafetyCaseSummary.build(evidence, opts, %{
      schema_contract: @safety_case_schema_contract,
      known_limits: capabilities().known_limits
    })
  end

  @doc """
  Builds an artifact-only schema migration and deprecation report.

  The report is a compatibility-routing aid. It snapshots executable schema
  contracts and caller-declared deprecation/future-contract hints; it does not
  rewrite artifacts or grant backward-compatibility guarantees by itself.
  """
  def schema_migration_report(opts \\ []) do
    OrbitalDynamics.Validation.SchemaMigrationReport.build(opts, %{
      schema_contract: @schema_migration_schema_contract,
      contracts: &OrbitalDynamics.Schema.contracts/0,
      compatibility_policy: &OrbitalDynamics.Schema.compatibility_policy/0
    })
  end

  @doc """
  Fetches one curated reference fixture by stable ID.
  """
  def reference_fixture(id) when is_binary(id),
    do: OrbitalDynamics.Validation.ReferenceFixtures.fetch(id)

  @doc """
  Verifies observed fixture values against a curated reference fixture.

  Observations are simple maps keyed by the fixture's expected fields. Numeric
  scalar and 3-vector values are compared with the fixture's declared tolerance.
  """
  def verify_reference_fixture(id, observations) when is_binary(id) and is_map(observations) do
    OrbitalDynamics.Validation.ReferenceFixtureVerification.verify(
      id,
      observations,
      reference_fixtures()
    )
  end

  def verify_reference_fixture(_id, _observations),
    do: {:error, {:invalid_field, "observations"}}

  @doc """
  Builds flat observations for product-level artifact contract fixtures.
  """
  def artifact_observations(contract, artifact) do
    OrbitalDynamics.Validation.ArtifactObservations.build(contract, artifact)
  end

  @doc """
  Builds a deterministic report for all curated reference fixtures.
  """
  def reference_fixture_report(observations_by_fixture) when is_map(observations_by_fixture) do
    OrbitalDynamics.Validation.ReferenceFixtureReport.build(
      observations_by_fixture,
      reference_fixtures(),
      &verify_reference_fixture/2
    )
  end

  @doc """
  Returns validation records relevant to a result set.
  """
  def records_for_result_set(%{assumptions: assumptions}) when is_map(assumptions) do
    OrbitalDynamics.Validation.ResultSetRecords.build(
      assumptions,
      registry(),
      OrbitalDynamics.Validation.Registry.propagator_ids(),
      OrbitalDynamics.Validation.Registry.output_ids()
    )
  end
end
