"""Make a compact looping preview from native Godot viewport captures."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image

paths=sorted((ROOT/'artifacts/animation-v3-frames').glob('*.png'))
images=[]
for path in paths:
    image=Image.open(path).convert('RGB')
    w,h=image.size
    # Crop away the testing HUD: these are unaltered gameplay character pixels.
    image=image.crop((int(w*.12),int(h*.34),int(w*.94),int(h*.90)))
    image=image.resize((820,315),Image.Resampling.LANCZOS)
    images.append(image)
palette=images[0].quantize(colors=128,method=Image.Quantize.MEDIANCUT)
frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in images]
output=ROOT/'artifacts/animation-v3.gif'
delays=[10 if i%3==0 else 20 for i in range(len(frames))]
frames[0].save(output,save_all=True,append_images=frames[1:],duration=delays,loop=0,optimize=True,disposal=1)
print(f'Preview: {len(frames)} frames, {output.stat().st_size:,} bytes')
