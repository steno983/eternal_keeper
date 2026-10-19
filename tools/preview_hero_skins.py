"""Compact native-rendered preview, with an editorial fade at the loop cut."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
frames=[]
for index,path in enumerate(sorted((ROOT/'artifacts/hero-skin-frames').glob('*.png'))):
    im=Image.open(path).convert('RGB').crop((75,125,1180,525))
    im=im.resize((995,360),Image.Resampling.LANCZOS)
    # Different actual cadences cannot all close on one short common loop.
    # Fade the recording boundary instead of altering anyone's playback speed.
    opacity=min(1.0,index/6.0,(95-index)/6.0)
    if opacity<1.0:
        im=Image.blend(Image.new('RGB',im.size,(24,40,50)),im,max(0.0,opacity))
    frames.append(im)
output=ROOT/'artifacts/heroes-dressed-run.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=[10 if i%3==0 else 20 for i in range(len(frames))],loop=0,disposal=2)
print(f'{output}: {len(frames)} frames, {output.stat().st_size:,} bytes')
