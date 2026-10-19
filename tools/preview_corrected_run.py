"""Build the 60 Hz comparison from unmodified native Godot captures."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image, ImageDraw
frames=[]
for path in sorted((ROOT/'artifacts/gait-frames').glob('*.png')):
 im=Image.open(path).convert('RGB')
 im=im.crop((110,65,1240,625)).resize((904,448),Image.Resampling.LANCZOS)
 draw=ImageDraw.Draw(im)
 draw.text((8,5),'PRIMA',fill=(225,194,140))
 draw.text((8,245),'GAMBE ARTICOLATE',fill=(120,220,210))
 frames.append(im)
output=ROOT/'artifacts/gait-correction.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=[10 if i%3==0 else 20 for i in range(len(frames))],loop=0,disposal=2)
print(f'{len(frames)} frames, {output.stat().st_size} bytes: {output}')
