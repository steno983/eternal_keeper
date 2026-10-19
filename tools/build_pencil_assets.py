"""Normalize complete pencil drawings and bake native SpriteFrames.
Sources stay intact. No body-part reconstruction or painted raster edits.
"""
from pathlib import Path
import sys,json,argparse,math
ROOT=Path(__file__).resolve().parents[1]
if sys.version_info.minor==14:sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image,ImageDraw
from build_sprite_frames import subjects,hip_anchor
OUT=ROOT/'assets/pencil'; SIZE=(512,416); PIVOT=(256,400)
HEIGHTS={'hero_0':210,'hero_1':270,'hero_2':278,'enemy_0':262,'enemy_1':255,'enemy_2':325}
def normalize(key):
    source=Image.open(OUT/'sources'/f'{key}.png').convert('RGBA')
    assert source.getchannel('A').getextrema()[0]==0,key+' needs transparent background'
    groups,_=subjects(source,6)
    counts=[len(g) for g in groups]
    assert counts==[4]*6,(key,counts)
    tiles=[tile for row in groups for tile in row]
    idle=tiles[0]; idle_bound=idle.getchannel('A').getbbox()
    factor=HEIGHTS[key]/(idle_bound[3]-idle_bound[1])
    # One scale for the entire actor, including its widest weapon pose.
    extent=0
    tallest=0
    for tile in tiles:
        bound=tile.getchannel('A').getbbox()
        anchor=hip_anchor(tile,bound,True)
        extent=max(extent,anchor,tile.width-anchor)
        tallest=max(tallest,bound[3])
    factor=min(factor,(SIZE[0]*0.5-8)/extent,(PIVOT[1]-8)/tallest)
    frames=[];report=[]
    for i,tile in enumerate(tiles):
        bounds=tile.getchannel('A').point(lambda p:255 if p>40 else 0).getbbox()
        anchor=hip_anchor(tile,bounds,True)
        resized=tile.resize((round(tile.width*factor),round(tile.height*factor)),Image.Resampling.LANCZOS)
        frame=Image.new('RGBA',SIZE)
        x=round(PIVOT[0]-anchor*factor);y=round(PIVOT[1]-bounds[3]*factor)
        assert x>=0 and x+resized.width<=SIZE[0] and y>=0,(key,i,'clipped',x,y,resized.size)
        frame.alpha_composite(resized,(x,y));frames.append(frame)
        report.append({'frame':i,'alpha':frame.getchannel('A').getextrema(),'bounds':frame.getchannel('A').getbbox()})
    atlas=Image.new('RGBA',(SIZE[0]*4,SIZE[1]*6))
    for i,frame in enumerate(frames):atlas.alpha_composite(frame,(i%4*SIZE[0],i//4*SIZE[1]))
    atlas.save(OUT/f'{key}-keys.png')
    if key.startswith('hero'):
        box={'hero_0':(226,190,290,270),'hero_1':(227,130,283,202),'hero_2':(257,122,318,194)}[key]
        head=frames[0].crop(box)
        head.save(OUT/f'{key}-portrait.png')
    preview=Image.new('RGB',(1024,1248),(241,233,215))
    for i,frame in enumerate(frames):
        im=frame.resize((256,208),Image.Resampling.LANCZOS)
        preview.paste(im,(i%4*256,i//4*208),im)
    preview.save(ROOT/f'artifacts/pencil-{key}-keys.png')
    return frames,report

def clips(key):
    hero=key.startswith('hero');index=int(key[-1])
    length=[.48,.36,.42][index] if hero else (.52 if index==1 else .54)
    contact=[.34,.24,.34][index] if hero else (.24/.52 if index==1 else .25/.54)
    weights=[contact*.45,contact*.55,.62-contact,.38]
    result={'idle':([0],[.8],True),'guard':([1],[.6],True),
        'run':(list(range(4,12)),[(.70 if hero and index==1 else .82 if hero and index==2 else .76 if hero else 1.0)/8]*8,True),
        'hurt':([3],[.22],False),'dodge':([6,7,8],[.05,.08,.06],False),
        'special':([1,2,1],[.20,.18,.12],False),'ranged':([1,2,0],[.46*.34,.20*.34,.34*.34],False),
        'windup':([12,13],[.35,.35],False)}
    for step in range(3):result['attack' if step==0 else f'attack_{step+1}']=(list(range(12+step*4,16+step*4)),[w*length for w in weights],False)
    return result

def save_resource(key,data):
    external=[];subs=[];entries=[];serial=0
    for name,(images,times,loop) in data.items():
        cols=min(8,len(images))
        atlas=Image.new('RGBA',(SIZE[0]*cols,SIZE[1]*math.ceil(len(images)/cols)))
        for i,im in enumerate(images):atlas.alpha_composite(im,(i%cols*SIZE[0],i//cols*SIZE[1]))
        filename=f'{key}-{name}.png';atlas.save(OUT/filename)
        external.append(f'[ext_resource type="Texture2D" path="res://assets/pencil/{filename}" id="{name}"]')
        fs=[]
        for i,duration in enumerate(times):
            serial+=1;rid=f'f{serial}'
            subs.append(f'[sub_resource type="AtlasTexture" id="{rid}"]\natlas = ExtResource("{name}")\nregion = Rect2({i%cols*SIZE[0]}, {i//cols*SIZE[1]}, {SIZE[0]}, {SIZE[1]})')
            fs.append('{"duration": %.9f, "texture": SubResource("%s")}' % (duration,rid))
        entries.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 1.0}' % (', '.join(fs),str(loop).lower(),name))
    text=f'[gd_resource type="SpriteFrames" load_steps={1+len(external)+serial} format=3]\n\n'+'\n\n'.join(external+subs)+'\n\n[resource]\nanimations = [\n'+',\n'.join(entries)+'\n]\n'
    (OUT/f'{key}.tres').write_text(text,encoding='utf-8')
def build(key):
    frames,report=normalize(key)
    data={}
    for name,(ids,times,loop) in clips(key).items():
        images=[];durations=[]
        steps=1
        for i,(idx,seconds) in enumerate(zip(ids,times)):
            start=frames[idx];end=frames[ids[(i+1)%len(ids)]] if loop or i<len(ids)-1 else frames[0]
            for sub in range(steps):
                images.append(start.copy())
                durations.append(seconds/steps)
        data[name]=(images,durations,loop)
    save_resource(key,data)
    (OUT/f'{key}-qa.json').write_text(json.dumps({'keys':report,'clips':{n:len(v[0]) for n,v in data.items()}},indent=2))
    print(key+': complete drawings baked',flush=True)
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('keys',nargs='*');args=parser.parse_args()
    source=Image.open(OUT/'sources/ruins.png').convert('RGBA')
    groups,_=subjects(source,1)
    assert len(groups[0])==3
    for name,tile in zip(['ruin','rail','brazier'],groups[0]):
        tile.crop(tile.getchannel('A').getbbox()).save(OUT/(name+'.png'))
    for key in args.keys or HEIGHTS:build(key)
