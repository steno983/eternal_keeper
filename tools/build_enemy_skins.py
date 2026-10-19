"""Rebuild the three nine-part enemy kits from preserved transparent sources."""
from pathlib import Path
import sys,json
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
from build_sprite_frames import subjects
SLOTS=['head','torso','pelvis','upper_arm','forearm','weapon','thigh','shin','boot']
for name in ['raider','archer','warden']:
    folder=ROOT/'assets'/(name+'_skin')
    source=Image.open(folder/'parts-source.png').convert('RGBA')
    assert source.getchannel('A').getextrema()[0]==0
    groups,_=subjects(source,3)
    assert [len(row) for row in groups]==[3,3,3]
    report={}
    for slot,tile in zip(SLOTS,[tile for row in groups for tile in row]):
        tile=tile.crop(tile.getchannel('A').getbbox())
        tile.thumbnail((256,256))
        tile.save(folder/(slot+'.png'))
        report[slot]={'size':tile.size,'alpha':tile.getchannel('A').getextrema()}
    (folder/'qa.json').write_text(json.dumps(report,indent=2))
    print(name+': nine parts; alpha verified')
