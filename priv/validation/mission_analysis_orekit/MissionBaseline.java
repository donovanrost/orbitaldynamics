import java.nio.file.*;
import java.io.*;
import java.util.*;
import org.hipparchus.geometry.euclidean.threed.*;
import org.hipparchus.ode.nonstiff.DormandPrince853Integrator;
import org.orekit.bodies.*;
import org.orekit.frames.*;
import org.orekit.forces.gravity.J2OnlyPerturbation;
import org.orekit.orbits.*;
import org.orekit.propagation.SpacecraftState;
import org.orekit.propagation.events.CylindricalShadowEclipseDetector;
import org.orekit.propagation.numerical.NumericalPropagator;
import org.orekit.time.*;
import org.orekit.utils.*;

/** Independent library computations using explicit matched inputs, not Elixir states. */
public final class MissionBaseline {
  private static double n(Properties p, String key) { return Double.parseDouble(p.getProperty(key)); }
  public static void main(String[] args) throws Exception {
    Locale.setDefault(Locale.ROOT);
    Path dir = Path.of(args[0]);
    Properties p = new Properties();
    try (Reader r = Files.newBufferedReader(dir.resolve("case.properties"))) { p.load(r); }
    Frame inertial = FramesFactory.getEME2000();
    AbsoluteDate epoch = new AbsoluteDate(2000, 1, 1, 12, 0, 0, TimeScalesFactory.getTAI());
    double mu = n(p,"mu_m3_s2"), radius = n(p,"radius_m");
    CircularOrbit initial = new CircularOrbit(n(p,"semi_major_axis_m"), 0, 0,
      Math.toRadians(n(p,"inclination_deg")), Math.toRadians(n(p,"raan_deg")),
      Math.toRadians(n(p,"argument_of_latitude_deg")), PositionAngleType.TRUE, inertial, epoch, mu);
    double[] abs = {1e-5,1e-5,1e-5,1e-8,1e-8,1e-8,1e-6};
    double[] rel = {1e-13,1e-13,1e-13,1e-13,1e-13,1e-13,1e-13};
    NumericalPropagator propagator = new NumericalPropagator(new DormandPrince853Integrator(0.001,30,abs,rel));
    propagator.setOrbitType(OrbitType.CARTESIAN);
    propagator.setInitialState(new SpacecraftState(initial));
    // NumericalPropagator supplies Newtonian attraction; this adds only J2.
    propagator.addForceModel(new J2OnlyPerturbation(mu, radius, n(p,"j2"), inertial));
    GeodeticPoint target = new GeodeticPoint(Math.toRadians(n(p,"target_latitude_deg")),
      Math.toRadians(n(p,"target_longitude_deg")), n(p,"target_altitude_m"));
    List<String> lines = Files.readAllLines(dir.resolve("environment.csv"));
    try (PrintWriter out = new PrintWriter(Files.newBufferedWriter(Path.of(args[1])))) {
      out.println("elapsed_s,x_m,y_m,z_m,vx_m_s,vy_m_s,vz_m_s,range_m,elevation_deg,target_sun_elevation_deg,off_nadir_deg,sunlit");
      for (String line : lines.subList(1, lines.size())) {
        double[] e = Arrays.stream(line.split(",")).mapToDouble(Double::parseDouble).toArray();
        AbsoluteDate date = epoch.shiftedBy(e[0]);
        SpacecraftState state = propagator.propagate(date);
        PVCoordinates pv = state.getPVCoordinates(inertial);
        Vector3D r = pv.getPosition(), v = pv.getVelocity();
        // Transform maps parent inertial axes to body axes: inverse of eastward body rotation.
        Frame fixed = new Frame(inertial, new Transform(date,
          new Rotation(Vector3D.PLUS_K, -e[1], RotationConvention.VECTOR_OPERATOR)), "sample-body");
        OneAxisEllipsoid sphere = new OneAxisEllipsoid(radius,0,fixed);
        TopocentricFrame site = new TopocentricFrame(sphere,target,"target");
        Vector3D ground = fixed.getTransformTo(inertial,date).transformPosition(sphere.transform(target));
        Vector3D sun = new Vector3D(e[2],e[3],e[4]).normalize();
        ConstantPVCoordinatesProvider solarProvider = new ConstantPVCoordinatesProvider(sun.scalarMultiply(1e20),inertial);
        boolean sunlit = new CylindricalShadowEclipseDetector(solarProvider,radius,new org.orekit.propagation.events.handlers.RecordAndContinue()).g(state) > 0;
        out.printf("%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s%n",
          e[0],r.getX(),r.getY(),r.getZ(),v.getX(),v.getY(),v.getZ(),
          site.getRange(r,inertial,date), Math.toDegrees(site.getElevation(r,inertial,date)),
          Math.toDegrees(site.getElevation(sun.scalarMultiply(1e20),inertial,date)),
          Math.toDegrees(Vector3D.angle(r.negate(),ground.subtract(r))),sunlit);
      }
    }
  }
}
