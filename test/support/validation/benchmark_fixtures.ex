defmodule OrbitalDynamics.Validation.BenchmarkFixtures do
  alias OrbitalDynamics.Validation

  def study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(study_benchmark_fixture())
  end

  def study_benchmark_fixture do
    read_json!("study_results/study_benchmark.json")
  end

  def distributed_concurrency_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_concurrency_benchmark_fixture())
  end

  def distributed_concurrency_benchmark_fixture do
    read_json!("study_results/distributed_concurrency_sweep.json")
  end

  def distributed_chunk_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_chunk_benchmark_fixture())
  end

  def distributed_chunk_benchmark_fixture do
    read_json!("study_results/distributed_chunk_sweep.json")
  end

  def distributed_monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_scaling_benchmark_fixture())
  end

  def distributed_monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_scaling.json")
  end

  def distributed_diagnostic_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_diagnostic_benchmark_fixture())
  end

  def distributed_diagnostic_benchmark_fixture do
    read_json!("study_results/distributed_diagnostic_sweep.json")
  end

  def distributed_monte_carlo_chunked_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_chunked_benchmark_fixture())
  end

  def distributed_monte_carlo_chunked_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_chunked.json")
  end

  def monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(monte_carlo_scaling_benchmark_fixture())
  end

  def monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/monte_carlo_scaling.json")
  end

  def nx_study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(nx_study_benchmark_fixture())
  end

  def nx_study_benchmark_fixture do
    read_json!("study_results/nx_study_benchmark.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
