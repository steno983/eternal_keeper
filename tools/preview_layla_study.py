"""Compact 60 Hz preview of the native Godot animation study capture."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
frames=[]
for file in sorted((ROOT/'artifacts/layla-study-frames').glob('*.png')):
    # Show only the new cycle: the two versions have different periods, so a
    # short looping GIF cannot close both timelines without a misleading jump.
    frame=Image.open(file).convert('RGB').crop((680,260,1150,590))
    frame=frame.resize((564,396),Image.Resampling.LANCZOS)
    frames.append(frame)
output=ROOT/'artifacts/layla-dressed-run.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=[10 if i%3==0 else 20 for i in range(len(frames))],loop=0,disposal=2)
print(f'{len(frames)} frames, {output.stat().st_size:,} bytes')
