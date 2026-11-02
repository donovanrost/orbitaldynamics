#!/usr/bin/env python3
"""Physical inputs only; independent of Elixir results. Fixed seed and explicit edge cases."""
import csv, math, random
from pathlib import Path
HERE = Path(__file__).resolve().parent
rng = random.Random(731904)
def unit(v):
    n = math.sqrt(sum(x*x for x in v)); return [x/n for x in v]
def quat(v):
    a = math.sqrt(sum(x*x for x in v))
    return [1,0,0,0] if a == 0 else [math.cos(math.radians(a)/2)] + [x/a*math.sin(math.radians(a)/2) for x in v]
def write(name,rows):
    with (HERE/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader()
        for row in rows:
            w.writerow({k:format(v,'.17g') if isinstance(v,float) else v for k,v in row.items()})
def xyz(prefix,v): return {prefix+k:x for k,x in zip('xyz',v)}
def qfields(prefix,v): return {prefix+k:x for k,x in zip('wxyz',v)}
orientations=[]
for i,direction in enumerate([[1,0,0],[-1,0,0],[0,1,0],[0,0,1],[0,0,-1]] + [unit([rng.uniform(-1,1) for _ in range(3)]) for _ in range(40)]):
    ref=[0,0,1] if abs(direction[2])<.95 else [1,0,0]
    mount=quat([0,90,0] if i==1 else [rng.uniform(-170,170) for _ in range(3)])
    orientations.append(dict(id=f'orientation-{i:02d}',**xyz('d_',direction),**xyz('ref_',ref),**qfields('mount_',mount),**xyz('v_',[.3,-.4,.8])))
write('orientation-input.csv',orientations)
motions=[]
def motion(id,q0,q1,w0,w1,gap,v,a,settle):
    motions.append(dict(id=id,**qfields('source_',q0),**qfields('target_',q1),**xyz('source_rate_',w0),**xyz('target_rate_',w1),gap_s=gap,max_rate_deg_s=v,max_accel_deg_s2=a,settling_s=settle))
motion('triangular',quat([0,0,0]),quat([0,0,5]),[0,0,0],[0,0,0],3,10,5,0)
motion('trapezoidal',quat([0,0,0]),quat([0,0,90]),[0,0,0],[0,0,0],15,10,5,2)
motion('rejected-short-gap',quat([0,0,0]),quat([0,0,90]),[0,0,0],[0,0,0],10,10,5,0)
motion('nonzero-endpoints',quat([20,5,-12]),quat([-50,10,30]),[3,2,1],[-2,4,1],50,10,5,2)
motion('half-turn',quat([0,0,0]),quat([180,0,0]),[0,0,0],[0,0,0],35,10,5,1)
motion('zero-angle',quat([12,-7,3]),quat([12,-7,3]),[0,0,0],[0,0,0],3,10,5,2)
for i in range(12):
    motion(f'motion-{i:02d}',quat([rng.uniform(-120,120) for _ in range(3)]),quat([rng.uniform(-120,120) for _ in range(3)]),[rng.uniform(-1,1) for _ in range(3)],[rng.uniform(-1,1) for _ in range(3)],80,4,.4,1)
write('motion-input.csv',motions)
beams=[]
def beam(id,r,s,n,lat=0,lon=0,cap=5,solar=.265,pad=0,rotation=0,mode='reflecting',back='two_sided_reflecting_by_assumption',expected='envelope',radius=1000):
    beams.append(dict(id=id,radius_km=radius,**xyz('r_',r),**xyz('sun_',unit(s)),**xyz('normal_',unit(n)),region_lat_deg=lat,region_lon_deg=lon,region_radius_km=cap,solar_radius_deg=solar,padding_deg=pad,rotation_rad=rotation,mode=mode,back=back,expected=expected))
beam('central-overlap',[1100,0,0],[0,1,0],[-1,1,0],expected='violated')
beam('far-side-cap',[1100,0,0],[0,1,0],[-1,1,0],lon=180,expected='supported')
beta=math.asin(1000/1100);psi=math.acos(1000/1100)
d=[-math.cos(beta+math.radians(.1)),math.sin(beta+math.radians(.1)),0]
beam('grazing-center-miss',[1100,0,0],[0,1,0],[d[0],d[1]+1,0],lon=math.degrees(psi),cap=1,expected='violated')
s=[-math.cos(beta-math.radians(.1)),math.sin(beta-math.radians(.1)),0]
beam('partial-eclipse',[1100,0,0],s,[s[0]-1,s[1],0],expected='violated')
beam('full-eclipse',[1100,0,0],[-math.cos(math.radians(.1)),math.sin(math.radians(.1)),0],[-1,0,0],expected='supported')
beam('unknown-mode',[1100,0,0],[0,1,0],[-1,1,0],mode='off',expected='unknown')
beam('blocked-mode',[1100,0,0],[0,1,0],[-1,1,0],mode='blocked_by_assumption',expected='supported')
beam('unknown-back-disk',[1100,0,0],[0,1,0],[math.cos(math.radians(.1)),math.sin(math.radians(.1)),0],back='unknown',expected='unknown')
beam('declared-nonreflecting-back',[1100,0,0],[0,1,0],[0,-1,0],back='non_reflecting_by_assumption',expected='supported')
# Include small caps near the limb and larger oblique caps, rotations and high latitudes.
for i in range(160):
    R=1000 if i%2==0 else 6378.1363
    altitude=rng.uniform(.04,.25)*R
    rhat=unit([rng.uniform(-1,1) for _ in range(3)])
    r=[(R+altitude)*x for x in rhat]
    # Region near the sub-spacecraft point, rotated independently in body longitude.
    base_lat=math.degrees(math.asin(rhat[2]));base_lon=math.degrees(math.atan2(rhat[1],rhat[0]))
    rotation=rng.uniform(-math.pi,math.pi)
    lat=max(-89.9,min(89.9,base_lat+rng.uniform(-25,25)))
    lon=(base_lon-math.degrees(rotation)+rng.uniform(-25,25)+180)%360-180
    cap=rng.choice([.1,1,10,40,100])*R/1000
    target=[R*math.cos(math.radians(lat))*math.cos(math.radians(lon)+rotation),R*math.cos(math.radians(lat))*math.sin(math.radians(lon)+rotation),R*math.sin(math.radians(lat))]
    toward=unit([target[j]-r[j] for j in range(3)])
    # Offset across the small solar cone as well as outside the cap envelope.
    offset=rng.choice([.001,.005,.02,.08])
    wanted=unit([toward[j]+rng.uniform(-offset,offset) for j in range(3)])
    sun=unit([rng.uniform(-1,1) for _ in range(3)])
    normal=unit([sun[j]+wanted[j] for j in range(3)])
    beam(f'envelope-{i:03d}',r,sun,normal,lat,lon,cap,pad=rng.choice([0,.02,.1]),rotation=rotation,radius=R)
write('beam-input.csv',beams)
profiles=[]
for i in range(12):
    profiles.append(dict(id=f'profile-{i:02d}',law='fixed_axis' if i<6 else 'two_axis',**xyz('axis_',unit([.3,-.4,.5])),**qfields('base_',quat([12,-7,3])),rate_deg_s=2,accel_deg_s2=.2,second_rate_deg_s=1.5,epoch_s=5+i,derivative_s=[.05,.25,.5][i%3]))
write('profile-input.csv',profiles)
