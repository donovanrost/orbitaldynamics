defmodule OrbitalDynamics.MissionAnalysis.Environments.Campaign do
  @moduledoc """
  Adapter for the existing source-bound JPL/IERS campaign environment dataset.

  This adapter is explicitly Earth/J2000/UTC and inherits the dataset's finite
  coverage and ERA-to-J2000 approximation. No UTC/TDB conversion is performed.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Environment
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider.Dataset

  @impl true
  def at(%Epoch{scale: :utc} = epoch, %Dataset{body: "earth", time_scale: "utc"} = dataset) do
    opts = [dataset: dataset, seconds_since_j2000: epoch.seconds_since_j2000]

    with {:ok, sun} <- Provider.fetch(:sun_direction, opts),
         {:ok, rotation} <- Provider.fetch(:earth_rotation, opts) do
      {:ok,
       %{
         frame: Frame.earth_inertial_j2000(),
         epoch: epoch,
         sun_direction: sun["sun_direction"],
         rotation_angle_rad: rotation["earth_rotation_angle_rad"]
       }}
    end
  end

  def at(_epoch, _dataset), do: {:error, :campaign_environment_requires_earth_j2000_utc}

  @impl true
  def describe(%Dataset{} = dataset) do
    %{
      "model" => "source_bound_campaign_environment",
      "table_id" => dataset.table_id,
      "provider_revision" => dataset.provider_revision,
      "dataset_revision" => dataset.dataset_revision,
      "coverage" => dataset.coverage,
      "sources" => dataset.sources,
      "known_limits" => dataset.known_limits,
      "content_verification" => dataset.content_verification
    }
  end
end
