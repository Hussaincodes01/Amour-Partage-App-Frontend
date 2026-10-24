# Generates the Amour Partagé mark (neon heart) as SVG + Android launcher/splash drawables.
# Same geometry as lib/core/widgets/logo.dart.
#
# Usage (from app/):
#   python3 tool/brand/generate_icons.py android/app/src/main/res ../brand/logo
#   node tool/brand/render_icons.js icon.svg android/app/src/main/res ../brand/logo   # PNG mipmaps (needs playwright)
import os, sys
RES = sys.argv[1]
BRAND = sys.argv[2]

def heart(x, y, w, h):
    P = lambda u, v: f"{x+u*w:.2f},{y+v*h:.2f}"
    return (f"M{P(.5,.9)} C{P(.36,.8)} {P(.04,.6)} {P(.04,.33)} C{P(.04,.17)} {P(.17,.06)} {P(.3,.06)} "
            f"C{P(.4,.06)} {P(.47,.12)} {P(.5,.2)} C{P(.53,.12)} {P(.6,.06)} {P(.7,.06)} "
            f"C{P(.83,.06)} {P(.96,.17)} {P(.96,.33)} C{P(.96,.6)} {P(.64,.8)} {P(.5,.9)} Z")

def mark_svg(s, tile=True, glow=True):
    """Same geometry as lib/core/widgets/logo.dart, in an s×s box."""
    ox, oy, ow, oh = s*.19, s*.22, s*.62, s*.56
    ix, iy, iw, ih = s*.38, s*.39, s*.24, s*.22
    out = []
    if tile:
        out.append(f'<rect width="{s}" height="{s}" rx="{s*.25}" fill="url(#tile)"/>')
        out.append(f'<rect x="{s*.01}" y="{s*.01}" width="{s*.98}" height="{s*.98}" rx="{s*.24}" fill="none" stroke="url(#edge)" stroke-width="{s*.02}"/>')
    if glow:
        out.append(f'<path d="{heart(ox,oy,ow,oh)}" fill="none" stroke="url(#neon)" stroke-width="{s*.1}" opacity=".55" filter="url(#blur)"/>')
    out.append(f'<path d="{heart(ox,oy,ow,oh)}" fill="none" stroke="url(#neon)" stroke-width="{s*.07}" stroke-linejoin="round"/>')
    out.append(f'<path d="{heart(ix,iy,iw,ih)}" fill="url(#core)"/>')
    out.append(f'<circle cx="{s*.505}" cy="{s*.5}" r="{s*.04}" fill="#F4D9FF" opacity=".9" filter="url(#soft)"/>')
    defs = f'''<defs>
  <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1C1030"/><stop offset="1" stop-color="#120A1E"/></linearGradient>
  <linearGradient id="edge" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FF3FB4" stop-opacity=".35"/><stop offset="1" stop-color="#8F5BFF" stop-opacity=".12"/></linearGradient>
  <linearGradient id="neon" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF3FB4"/><stop offset="1" stop-color="#8F5BFF"/></linearGradient>
  <linearGradient id="core" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E0409E"/><stop offset="1" stop-color="#8F5BFF"/></linearGradient>
  <filter id="blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="{s*.06}"/></filter>
  <filter id="soft" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="{s*.025}"/></filter>
</defs>'''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {s} {s}" width="{s}" height="{s}">{defs}{"".join(out)}</svg>'

open('icon.svg','w').write(mark_svg(512))
open('mark.svg','w').write(mark_svg(512, tile=False))

# Adaptive foreground: 108dp canvas, mark scaled into the 66dp safe zone.
def vector_foreground(viewport=108, scale=0.62, glow_alpha='8C'):
    s = viewport*scale; off = (viewport - s)/2
    ox, oy, ow, oh = off+s*.19, off+s*.22, s*.62, s*.56
    ix, iy, iw, ih = off+s*.38, off+s*.39, s*.24, s*.22
    grad = lambda x1,y1,x2,y2,c1,c2: f'''<aapt:attr name="android:{{attr}}"><gradient android:type="linear" android:startX="{x1:.1f}" android:startY="{y1:.1f}" android:endX="{x2:.1f}" android:endY="{y2:.1f}" android:startColor="{c1}" android:endColor="{c2}"/></aapt:attr>'''
    neon = grad(ox,oy,ox+ow,oy+oh,'#FFFF3FB4','#FF8F5BFF')
    core = grad(ix,iy,ix+iw,iy+ih,'#FFE0409E','#FF8F5BFF')
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp" android:viewportWidth="{viewport}" android:viewportHeight="{viewport}">
    <path android:pathData="{heart(ox,oy,ow,oh)}" android:strokeWidth="{s*.12:.2f}" android:strokeAlpha="0.28" android:strokeLineJoin="round">
        {neon.replace('{attr}','strokeColor')}
    </path>
    <path android:pathData="{heart(ox,oy,ow,oh)}" android:strokeWidth="{s*.07:.2f}" android:strokeLineJoin="round">
        {neon.replace('{attr}','strokeColor')}
    </path>
    <path android:pathData="{heart(ix,iy,iw,ih)}">
        {core.replace('{attr}','fillColor')}
    </path>
</vector>
'''

def vector_mono(viewport=108, scale=0.62):
    s = viewport*scale; off = (viewport - s)/2
    ox, oy, ow, oh = off+s*.19, off+s*.22, s*.62, s*.56
    ix, iy, iw, ih = off+s*.38, off+s*.39, s*.24, s*.22
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="{viewport}" android:viewportHeight="{viewport}">
    <path android:pathData="{heart(ox,oy,ow,oh)}" android:strokeColor="#FFFFFFFF" android:strokeWidth="{s*.08:.2f}" android:strokeLineJoin="round"/>
    <path android:pathData="{heart(ix,iy,iw,ih)}" android:fillColor="#FFFFFFFF"/>
</vector>
'''

bg = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="54" android:startY="0" android:endX="54" android:endY="108" android:startColor="#FF1C1030" android:endColor="#FF120A1E"/>
        </aapt:attr>
    </path>
</vector>
'''
d = os.path.join(RES,'drawable'); os.makedirs(d, exist_ok=True)
open(os.path.join(d,'ic_launcher_foreground.xml'),'w').write(vector_foreground())
open(os.path.join(d,'ic_launcher_monochrome.xml'),'w').write(vector_mono())
open(os.path.join(d,'ic_launcher_background.xml'),'w').write(bg)
# Android 12 splash icon: 288dp canvas (viewport 108), content inside the 192dp circle.
open(os.path.join(d,'ic_splash.xml'),'w').write(vector_foreground(scale=0.66))
a = os.path.join(RES,'mipmap-anydpi-v26'); os.makedirs(a, exist_ok=True)
adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
'''
open(os.path.join(a,'ic_launcher.xml'),'w').write(adaptive)
open(os.path.join(a,'ic_launcher_round.xml'),'w').write(adaptive)
# Pre-26 splash: dark window with the vector mark centred.
launch = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/amour_background"/>
    <item android:drawable="@drawable/ic_launcher_foreground" android:gravity="center" android:width="160dp" android:height="160dp"/>
</layer-list>
'''
for name in ('drawable','drawable-v21'):
    p=os.path.join(RES,name); os.makedirs(p, exist_ok=True); open(os.path.join(p,'launch_background.xml'),'w').write(launch)
os.makedirs(BRAND, exist_ok=True)
open(os.path.join(BRAND,'amour-partage-icon.svg'),'w').write(mark_svg(512))
open(os.path.join(BRAND,'amour-partage-mark.svg'),'w').write(mark_svg(512, tile=False))
print('ok')
