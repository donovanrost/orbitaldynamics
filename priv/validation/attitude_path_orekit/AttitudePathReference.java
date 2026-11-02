import java.nio.file.*;
import java.io.*;
import java.util.*;
import org.hipparchus.geometry.euclidean.threed.*;
import org.hipparchus.analysis.solvers.BracketingNthOrderBrentSolver;
import org.hipparchus.ode.*;
import org.hipparchus.ode.nonstiff.DormandPrince853Integrator;
import org.orekit.bodies.*;
import org.orekit.frames.*;
import org.orekit.propagation.SpacecraftState;
import org.orekit.time.*;
import org.orekit.utils.*;

/** External library calculations; no calls to the Elixir implementation. */
public final class AttitudePathReference {
  static final RotationConvention ACTIVE = RotationConvention.VECTOR_OPERATOR;
  static final Frame INERTIAL = FramesFactory.getEME2000();
  static final AbsoluteDate DATE = new AbsoluteDate(2000,1,1,12,0,0,TimeScalesFactory.getTAI());
  static List<Map<String,String>> read(Path file) throws Exception {
    List<String> lines=Files.readAllLines(file); String[] keys=lines.get(0).split(",");
    List<Map<String,String>> rows=new ArrayList<>();
    for (String line:lines.subList(1,lines.size())) {
      String[] values=line.split(",",-1); if(values.length!=keys.length) throw new IllegalArgumentException("CSV width");
      Map<String,String> row=new LinkedHashMap<>();for(int i=0;i<keys.length;i++)row.put(keys[i],values[i]);rows.add(row);
    }return rows;
  }
  static double n(Map<String,String> r,String k){return Double.parseDouble(r.get(k));}
  static Vector3D v(Map<String,String> r,String p){return new Vector3D(n(r,p+"x"),n(r,p+"y"),n(r,p+"z"));}
  // Hipparchus quaternion coordinates use the opposite vector sign for these active rotations.
  static Rotation q(Map<String,String> r,String p){return new Rotation(n(r,p+"w"),-n(r,p+"x"),-n(r,p+"y"),-n(r,p+"z"),true);}
  static double[] hamilton(Rotation r){return new double[]{r.getQ0(),-r.getQ1(),-r.getQ2(),-r.getQ3()};}
  static Rotation increment(Vector3D degrees){double a=degrees.getNorm();return a==0?Rotation.IDENTITY:new Rotation(degrees,a*Math.PI/180,ACTIVE);}
  static void row(PrintWriter out,Object... values){
    StringJoiner join=new StringJoiner(",");for(Object x:values)join.add(x instanceof Double?String.format(Locale.ROOT,"%.17g",x):x.toString());out.println(join);
  }
  static PrintWriter output(Path dir,String file,String header)throws Exception{
    PrintWriter p=new PrintWriter(Files.newBufferedWriter(dir.resolve(file)));p.println(header);return p;
  }
  public static void main(String[] args)throws Exception{
    Locale.setDefault(Locale.ROOT);Path source=Path.of(args[0]),out=Path.of(args[1]);Files.createDirectories(out);
    Rotation z90=new Rotation(Vector3D.PLUS_K,Math.PI/2,ACTIVE);
    if(z90.applyTo(Vector3D.PLUS_I).distance(Vector3D.PLUS_J)>1e-14 || new Rotation(z90.getQ0(),z90.getQ1(),z90.getQ2(),z90.getQ3(),true).applyTo(Vector3D.PLUS_I).distance(Vector3D.PLUS_J)>1e-14)throw new IllegalStateException("rotation convention");
    orientations(source,out); profiles(source,out); motions(source,out); beams(source,out);
  }
  static void orientations(Path source,Path out)throws Exception{
    try(PrintWriter p=output(out,"orientation-reference.csv","id,qw,qx,qy,qz,vx,vy,vz,bx,by,bz")){
      for(Map<String,String> r:read(source.resolve("orientation-input.csv"))){
        Rotation payload=new Rotation(Vector3D.PLUS_K,Vector3D.PLUS_I,v(r,"d_"),v(r,"ref_"));
        Rotation body=payload.compose(q(r,"mount_"),ACTIVE);
        Vector3D result=body.applyTo(v(r,"v_")),boresight=body.applyTo(Vector3D.PLUS_K);
        double[] h=hamilton(body);
        row(p,r.get("id"),h[0],h[1],h[2],h[3],result.getX(),result.getY(),result.getZ(),boresight.getX(),boresight.getY(),boresight.getZ());
      }
    }
  }
  static Rotation profile(Map<String,String> r,double t){
    double angle=n(r,"rate_deg_s")*t+.5*n(r,"accel_deg_s2")*t*t;
    Rotation first=new Rotation(r.get("law").equals("fixed_axis")?v(r,"axis_"):Vector3D.PLUS_I,Math.toRadians(angle),ACTIVE);
    Rotation moving=r.get("law").equals("fixed_axis")?first:first.compose(new Rotation(Vector3D.PLUS_J,Math.toRadians(n(r,"second_rate_deg_s")*t),ACTIVE),ACTIVE);
    return moving.compose(q(r,"base_"),ACTIVE);
  }
  static Vector3D delta(Rotation before,Rotation after,double dt){
    Rotation d=after.compose(before.revert(),ACTIVE);
    return d.getAxis(ACTIVE).scalarMultiply(Math.toDegrees(d.getAngle())/dt);
  }
  static void profiles(Path source,Path out)throws Exception{
    try(PrintWriter p=output(out,"profile-reference.csv","id,wx,wy,wz,ax,ay,az,true_wx,true_wy,true_wz,true_ax,true_ay,true_az")){
      for(Map<String,String> r:read(source.resolve("profile-input.csv"))){
        double t=n(r,"epoch_s"),h=n(r,"derivative_s");
        Vector3D rate=delta(profile(r,t-h),profile(r,t+h),2*h);
        Vector3D before=delta(profile(r,t-2*h),profile(r,t),2*h),after=delta(profile(r,t),profile(r,t+2*h),2*h);
        Vector3D acceleration=after.subtract(before).scalarMultiply(1/(2*h));
        Vector3D trueRate,trueAcceleration;
        if(r.get("law").equals("fixed_axis")){
          trueRate=v(r,"axis_").normalize().scalarMultiply(n(r,"rate_deg_s")+n(r,"accel_deg_s2")*t);
          trueAcceleration=v(r,"axis_").normalize().scalarMultiply(n(r,"accel_deg_s2"));
        }else{
          double x=Math.toRadians(n(r,"rate_deg_s")*t+.5*n(r,"accel_deg_s2")*t*t),dx=n(r,"rate_deg_s")+n(r,"accel_deg_s2")*t,b=n(r,"second_rate_deg_s");
          trueRate=new Vector3D(dx,b*Math.cos(x),b*Math.sin(x));
          trueAcceleration=new Vector3D(n(r,"accel_deg_s2"),-b*Math.sin(x)*Math.toRadians(dx),b*Math.cos(x)*Math.toRadians(dx));
        }
        row(p,r.get("id"),rate.getX(),rate.getY(),rate.getZ(),acceleration.getX(),acceleration.getY(),acceleration.getZ(),trueRate.getX(),trueRate.getY(),trueRate.getZ(),trueAcceleration.getX(),trueAcceleration.getY(),trueAcceleration.getZ());
      }
    }
  }
  static void motions(Path source,Path out)throws Exception{
    List<Map<String,String>> phases=read(source.resolve("phase-input.csv"));
    try(PrintWriter summary=output(out,"motion-reference.csv","id,required_s,rest_angle_deg,feasible");
        PrintWriter samples=output(out,"motion-samples.csv","id,elapsed_s,qw,qx,qy,qz,wx_deg_s,wy_deg_s,wz_deg_s")){
      for(Map<String,String> r:read(source.resolve("motion-input.csv"))){
        double a=n(r,"max_accel_deg_s2"),vmax=n(r,"max_rate_deg_s"),gap=n(r,"gap_s");
        Vector3D w0=v(r,"source_rate_"),w1=v(r,"target_rate_");
        Rotation stopped=increment(w0.scalarMultiply(w0.getNorm()/a/2)).compose(q(r,"source_"),ACTIVE);
        Rotation preramp=increment(w1.scalarMultiply(-w1.getNorm()/a/2)).compose(q(r,"target_"),ACTIVE);
        double angle=Math.toDegrees(Rotation.distance(stopped,preramp));
        double slew=angle<1e-12?0:new BracketingNthOrderBrentSolver(1e-12,5).solve(200,t->{
          double reachable=t<=2*vmax/a?a*t*t/4:vmax*(t-vmax/a);return reachable-angle;
        },0,2+2*Math.sqrt(angle/a)+angle/vmax+2*vmax/a);
        double required=(w0.getNorm()+w1.getNorm())/a+slew+n(r,"settling_s");
        boolean feasible=w0.getNorm()<=vmax && w1.getNorm()<=vmax && required<=gap;
        row(summary,r.get("id"),required,angle,feasible);
        if(!feasible)continue;
        double[] initial=hamilton(q(r,"source_"));
        double[] y={initial[0],initial[1],initial[2],initial[3],Math.toRadians(w0.getX()),Math.toRadians(w0.getY()),Math.toRadians(w0.getZ())};
        row(samples,r.get("id"),0.0,y[0],y[1],y[2],y[3],Math.toDegrees(y[4]),Math.toDegrees(y[5]),Math.toDegrees(y[6]));
        for(Map<String,String> phase:phases){if(!phase.get("id").equals(r.get("id")))continue;
          double start=n(phase,"starts_s"),end=n(phase,"ends_s");if(end<=start)continue;
          Vector3D acc=new Vector3D(Math.toRadians(n(phase,"ax_deg_s2")),Math.toRadians(n(phase,"ay_deg_s2")),Math.toRadians(n(phase,"az_deg_s2")));
          OrdinaryDifferentialEquation ode=new OrdinaryDifferentialEquation(){
            public int getDimension(){return 7;}
            public double[] computeDerivatives(double t,double[] s){
              Vector3D omega=new Vector3D(s[4],s[5],s[6]),vector=new Vector3D(s[1],s[2],s[3]);
              Vector3D dv=new Vector3D(.5*s[0],omega,.5,Vector3D.crossProduct(omega,vector));
              return new double[]{-.5*Vector3D.dotProduct(omega,vector),dv.getX(),dv.getY(),dv.getZ(),acc.getX(),acc.getY(),acc.getZ()};
            }};
          double t=start;
          while(t<end){double next=Math.min(end,t+.25);if(next==t)throw new IllegalStateException("time precision");
            DormandPrince853Integrator integrator=new DormandPrince853Integrator(1e-8,.25,1e-13,1e-13);
            y=integrator.integrate(ode,new ODEState(0,y),next-t).getPrimaryState();t=next;
            row(samples,r.get("id"),t,y[0],y[1],y[2],y[3],Math.toDegrees(y[4]),Math.toDegrees(y[5]),Math.toDegrees(y[6]));
          }
        }
      }
    }
  }
  static Vector3D hit(OneAxisEllipsoid sphere,Vector3D r,Vector3D d)throws Exception{
    Line line=new Line(r,r.add(d.scalarMultiply(1000)),1e-8);
    Vector3D body=sphere.getCartesianIntersectionPoint(line,r,INERTIAL,DATE);
    if(body==null)return null;
    Vector3D inertial=sphere.getBodyFrame().getTransformTo(INERTIAL,DATE).transformPosition(body);
    return Vector3D.dotProduct(inertial.subtract(r),d)>0?inertial:null;
  }
  static void beams(Path source,Path out)throws Exception{
    try(PrintWriter p=output(out,"beam-reference.csv","id,dx,dy,dz,hit,hx_km,hy_km,hz_km,lat_deg,lon_deg,sun_earth_deg,limb_deg,solar_deg,visibility,cap_samples,cone_witnesses,direct_solar_witnesses,witness_x_km,witness_y_km,witness_z_km,min_cap_angle_deg")){
      for(Map<String,String> c:read(source.resolve("beam-input.csv"))){
        double radius=n(c,"radius_km")*1000,solar=Math.toRadians(n(c,"solar_radius_deg")),cone=solar+Math.toRadians(n(c,"padding_deg"));
        Frame fixed=new Frame(INERTIAL,new Transform(DATE,new Rotation(Vector3D.PLUS_K,-n(c,"rotation_rad"),ACTIVE)),"sample-body");
        OneAxisEllipsoid sphere=new OneAxisEllipsoid(radius,0,fixed);
        Vector3D r=v(c,"r_").scalarMultiply(1000),sun=v(c,"sun_").normalize(),normal=v(c,"normal_").normalize();
        Rotation reflection=new Rotation(normal,Math.PI,ACTIVE);Vector3D beam=reflection.applyTo(sun);
        Vector3D intersection=hit(sphere,r,beam);Vector3D cart=intersection==null?Vector3D.ZERO:intersection.scalarMultiply(.001);
        GeodeticPoint location=intersection==null?null:sphere.transform(intersection,INERTIAL,DATE);
        double L=1e18;
        Vector3D solarPosition=r.add(sun.scalarMultiply(L));
        ExtendedPositionProvider emitter=new ExtendedPositionProvider(){
          public Vector3D getPosition(AbsoluteDate date,Frame frame){return INERTIAL.getStaticTransformTo(frame,date).transformPosition(solarPosition);}
          public <T extends org.hipparchus.CalculusFieldElement<T>> FieldVector3D<T> getPosition(FieldAbsoluteDate<T> date,Frame frame){
            return INERTIAL.getStaticTransformTo(frame,date).transformPosition(new FieldVector3D<T>(date.getField(),solarPosition));
          }
        };
        OccultationEngine engine=new OccultationEngine(emitter,L*Math.sin(solar),sphere);
        SpacecraftState state=new SpacecraftState(new AbsolutePVCoordinates(INERTIAL,DATE,new PVCoordinates(r,Vector3D.ZERO)));
        OccultationEngine.OccultationAngles angles=engine.angles(state);
        String visibility=angles.getSeparation()+angles.getOccultedApparentRadius()<angles.getLimbRadius()?"full":
          angles.getSeparation()-angles.getOccultedApparentRadius()>angles.getLimbRadius()?"clear":"partial";
        Vector3D centerBody=sphere.transform(new GeodeticPoint(Math.toRadians(n(c,"region_lat_deg")),Math.toRadians(n(c,"region_lon_deg")),0));
        Vector3D center=fixed.getTransformTo(INERTIAL,DATE).transformPosition(centerBody).normalize();
        Rotation capFrame=new Rotation(Vector3D.PLUS_K,center);
        int count=0,coneCount=0,directCount=0;double minimum=180;Vector3D witness=Vector3D.ZERO;
        double cap=n(c,"region_radius_km")*1000/radius;
        // Direct sampling of the spherical cap; no production enclosing-ball/visibility shortcut.
        for(int radial=0;radial<=16;radial++)for(int az=0;az<(radial==0?1:128);az++){
          double rho=cap*radial/16,phi=2*Math.PI*az/128;
          Vector3D point=capFrame.applyTo(new Vector3D(Math.sin(rho)*Math.cos(phi),Math.sin(rho)*Math.sin(phi),Math.cos(rho))).scalarMultiply(radius);
          Vector3D toward=point.subtract(r).normalize();Vector3D first=hit(sphere,r,toward);count++;
          if(first==null || first.distance(point)>.01)continue;
          double separation=Vector3D.angle(beam,toward);minimum=Math.min(minimum,Math.toDegrees(separation));
          if(separation<cone-1e-10){coneCount++;if(witness.getNorm()==0)witness=point.scalarMultiply(.001);}
          Vector3D incident=reflection.applyTo(toward);
          boolean knownReflectingBack=c.get("back").equals("two_sided_reflecting_by_assumption");
          if(Vector3D.angle(incident,sun)<solar-1e-10 && ((knownReflectingBack && Math.abs(Vector3D.dotProduct(incident,normal))>1e-10) || Vector3D.dotProduct(incident,normal)>1e-10) && hit(sphere,r,incident)==null)directCount++;
        }
        row(p,c.get("id"),beam.getX(),beam.getY(),beam.getZ(),intersection!=null,cart.getX(),cart.getY(),cart.getZ(),location==null?0:Math.toDegrees(location.getLatitude()),location==null?0:Math.toDegrees(location.getLongitude()),
          Math.toDegrees(angles.getSeparation()),Math.toDegrees(angles.getLimbRadius()),Math.toDegrees(angles.getOccultedApparentRadius()),visibility,count,coneCount,directCount,witness.getX(),witness.getY(),witness.getZ(),minimum);
      }
    }
  }
}
