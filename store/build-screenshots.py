# -*- coding: utf-8 -*-
"""Monta las capturas del celular sobre lienzos 1080x1920 (9:16) con la marca."""
import io, os, base64, subprocess, sys
from PIL import Image

SP    = os.path.dirname(os.path.abspath(__file__))  # carpeta store/
SRC   = r"C:\Proyectos_personales\EducaNexo360\Otros\APP\FOTOS_ACTUALES"
PROJ  = r"c:\Proyectos_personales\EducaNexo360\educanexo360_app"
OUT   = os.path.join(PROJ, "store", "screenshots")
CHROME= r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# Recorte de las barras del sistema (medido sobre las capturas de 720x1610)
CROP_TOP, CROP_BOTTOM = 78, 92

SHOTS = [
    ("dashboard.jpeg",   "Todo el colegio\nen una pantalla",   "Mensajes, eventos y tareas al abrir la app"),
    ("calendario.jpeg",  "Nunca te pierdas\nun evento",        "El calendario escolar siempre contigo"),
    ("tareas.jpeg",      "Las tareas,\nsiempre a la vista",    "Con fecha límite, materia y material de apoyo"),
    ("mensajeria1.jpeg", "Habla directo\ncon los docentes",    "Mensajería interna entre la familia y el colegio"),
    ("anuncios.jpeg",    "Comunicados\nque sí llegan",         "Las circulares del colegio, sin papeles perdidos"),
    ("asistencia.jpeg",  "Asistencia al día,\nsin papeleo",    "El docente la registra en segundos"),
]

TPL = u"""<!doctype html><html><head><meta charset="utf-8">
<style>{fonts}</style>
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{background:#000}}
.canvas{{
  position:relative;width:1080px;height:1920px;overflow:hidden;
  font-family:'Manrope',sans-serif;
  background:
    radial-gradient(90% 60% at 82% 4%, rgba(45,212,191,.34) 0%, rgba(13,148,136,0) 58%),
    radial-gradient(80% 50% at 8% 100%, rgba(5,150,105,.42) 0%, rgba(5,150,105,0) 62%),
    linear-gradient(160deg,#032b1d 0%,#064e3b 45%,#065f46 78%,#0b6a5a 100%);
}}
.grid{{position:absolute;inset:0;
  background-image:linear-gradient(rgba(255,255,255,.05) 1px,transparent 1px),
                   linear-gradient(90deg,rgba(255,255,255,.05) 1px,transparent 1px);
  background-size:64px 64px;
  -webkit-mask-image:radial-gradient(75% 55% at 50% 6%,#000 10%,transparent 72%);}}
.grain{{position:absolute;inset:-30%;opacity:.26;mix-blend-mode:overlay;
  background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3'/></filter><rect width='200' height='200' filter='url(%23n)' opacity='.55'/></svg>");}}
.head{{position:absolute;top:96px;left:0;width:100%;padding:0 84px;text-align:center;z-index:3}}
h1{{font-family:'Fraunces',Georgia,serif;font-weight:900;font-size:66px;line-height:1.03;
   letter-spacing:-.022em;color:#fff;text-shadow:0 8px 30px rgba(0,0,0,.35);white-space:pre-line}}
.rule{{width:86px;height:4px;margin:26px auto 20px;border-radius:2px;
   background:linear-gradient(90deg,rgba(245,158,11,0),#F59E0B,rgba(245,158,11,0))}}
.sub{{font-size:29px;font-weight:500;color:rgba(209,250,229,.88);line-height:1.35}}
.shot{{position:absolute;left:50%;top:398px;transform:translateX(-50%);
   width:720px;border-radius:30px;overflow:hidden;
   box-shadow:0 46px 90px -26px rgba(0,0,0,.72),0 0 0 2px rgba(255,255,255,.22);}}
.shot img{{display:block;width:720px}}
</style></head><body>
<div class="canvas">
  <div class="grid"></div>
  <div class="head">
    <h1>{title}</h1>
    <div class="rule"></div>
    <p class="sub">{sub}</p>
  </div>
  <div class="shot"><img src="data:image/jpeg;base64,{img}"></div>
  <div class="grain"></div>
</div></body></html>"""

fonts = io.open(os.path.join(SP, "fonts-inline.css"), encoding="utf-8").read()
os.makedirs(OUT, exist_ok=True)
ok = True

for i, (fname, title, sub) in enumerate(SHOTS, 1):
    im = Image.open(os.path.join(SRC, fname)).convert("RGB")
    w, h = im.size
    im = im.crop((0, CROP_TOP, w, h - CROP_BOTTOM))          # fuera barras del sistema
    buf = io.BytesIO(); im.save(buf, "JPEG", quality=95)
    b64 = base64.b64encode(buf.getvalue()).decode()

    html = TPL.format(fonts=fonts, title=title, sub=sub, img=b64)
    hp = os.path.join(SP, "shot_%d.html" % i)
    io.open(hp, "w", encoding="utf-8").write(html)

    out = os.path.join(OUT, "%02d-%s.png" % (i, fname.replace(".jpeg", "")))
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--window-size=1080,1920",
                    "--virtual-time-budget=4000", "--screenshot=" + out,
                    "file:///" + hp.replace("\\", "/")],
                   capture_output=True)

    r = Image.open(out)
    good = r.size == (1080, 1920) and r.mode == "RGB"
    ok = ok and good
    print(("OK " if good else "MAL") + "  %-26s %s  %s  %4d KB  capture recortada %dx%d"
          % (os.path.basename(out), r.size, r.mode,
             os.path.getsize(out)//1024, im.size[0], im.size[1]))

print("\nTodas 1080x1920 sin alfa:", ok)
print("Proporcion:", 1920/1080, "= 16/9 ->", abs(1920/1080 - 16/9) < 1e-9)
print("Regla de Google (max <= 2x min):", 1920 <= 2*1080)
