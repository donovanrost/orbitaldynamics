defmodule OrbitalDynamics.Study.Manifest.ValueSchema do
  @moduledoc false

  import OrbitalDynamics.Study.Manifest.SchemaProperty

  def target_identity_schema do
    object_property(%{
      "id" => string_property(),
      "target_id" => string_property()
    })
  end

  def ground_station_identity_schema do
    object_property(%{
      "id" => string_property(),
      "station_id" => string_property(),
      "ground_station_id" => string_property()
    })
  end

  def spacecraft_identity_schema do
    object_property(%{
      "id" => string_property(),
      "spacecraft_id" => string_property(),
      "satellite_id" => string_property()
    })
  end

  def vector3_schema do
    %{
      "type" => "array",
      "items" => number_property(),
      "minItems" => 3,
      "maxItems" => 3
    }
  end
end
