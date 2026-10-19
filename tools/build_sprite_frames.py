"""Normalize generated sheets, align hips/feet and write native Godot SpriteFrames.

No retouching or painted-frame synthesis: only deterministic slicing, placement,
resizing and atlas assembly. Original source files are retained beside the atlas.
"""
from pathlib import Path
import sys, math, json, hashlib, statistics
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.tools/python'))
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/animation_v2'
SIZE = (384, 320)
PIVOT = (192, 306)

def bounds_for(image, rows, content_height=None):
    alpha = image.getchannel('A')
    w, actual_height = image.size
    height = content_height or actual_height
    counts = [sum(v > 90 for v in alpha.crop((0,y,w,y+1)).tobytes()) for y in range(height)]
    result = [0]
    for r in range(1,rows):
        expected = r * height / rows
        lo, hi = int(expected-height/rows*.23), int(expected+height/rows*.23)
        result.append(min(range(lo, hi), key=lambda y: counts[y] + abs(y-expected)*.05))
    return result + [height]

def hip_anchor(tile, box, facing_right):
    # Weight torso pixels, never the tip of a weapon or the trailing cloak.
    a = tile.getchannel('A')
    w,h = tile.size
    y0 = int(box[1] + (box[3]-box[1])*.38)
    y1 = int(box[1] + (box[3]-box[1])*.69)
    center = tile.info.get('anchor_center',w * (.57 if facing_right else .49))
    reference_width = tile.info.get('cell_width',w)
    weights = []
    for x in range(w):
        mass = sum(a.crop((x,y0,x+1,y1)).tobytes()) / 255
        weights.append(mass * math.exp(-((x-center)/(reference_width*.15))**2))
    return sum(x*v for x,v in enumerate(weights))/max(1,sum(weights))

def subjects(image, rows, content_height=None, facing_right=True):
    """Connected-subject slicing tolerates weapons crossing nominal grid cells.

    We never copy a neighbouring character's cape fragment into another frame.
    Detached projectile/glow islands are left to the actual game's VFX system.
    """
    w,h=image.size
    mask=bytearray(v>80 for v in image.getchannel('A').tobytes())
    components=[]
    for first in range(w*h):
        if not mask[first]: continue
        stack=[first];mask[first]=0;pixels=[];left=w;right=0;top=h;bottom=0;sum_x=0
        while stack:
            p=stack.pop();pixels.append(p);x=p%w;y=p//w
            sum_x+=x;left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)
            for off in [-w,w,-1,1]:
                q=p+off
                if 0<=q<w*h and mask[q] and (abs(off)!=1 or q//w==y):
                    mask[q]=0;stack.append(q)
        if len(pixels)>2500:
            components.append((pixels,(left,top,right+1,bottom+1),sum_x/len(pixels)))
    bounds=bounds_for(image,rows,content_height)
    groups=[[] for _ in range(rows)]
    for pixels,box,center in components:
        row=min(range(rows),key=lambda r:abs(box[3]-(bounds[r+1]-9)))
        pad=3
        crop_box=(max(0,box[0]-pad),max(0,box[1]-pad),min(w,box[2]+pad),min(h,box[3]+pad))
        cw,ch=crop_box[2]-crop_box[0],crop_box[3]-crop_box[1]
        values=bytearray(cw*ch)
        for p in pixels:
            values[(p//w-crop_box[1])*cw+p%w-crop_box[0]]=255
        subject=Image.frombytes('L',(cw,ch),bytes(values)).filter(ImageFilter.MaxFilter(5))
        tile=image.crop(crop_box)
        tile.putalpha(ImageChops.multiply(tile.getchannel('A'),subject))
        groups[row].append((center,tile,crop_box))
    result=[]
    for group in groups:
        tiles=[]
        for col,(_,tile,crop_box) in enumerate(sorted(group,key=lambda item:item[0])):
            tile.info['anchor_center']=(col+(.57 if facing_right else .49))*w/4-crop_box[0]
            tile.info['cell_width']=w/4
            tiles.append(tile)
        result.append(tiles)
    return result,bounds

def write_resource(key, clips, count):
    lines = [f'[gd_resource type="SpriteFrames" load_steps={count+2} format=3]', '',
             f'[ext_resource type="Texture2D" path="res://assets/animation_v2/{key}-atlas.png" id="1"]', '']
    for i in range(count):
        lines += [f'[sub_resource type="AtlasTexture" id="f{i}"]', 'atlas = ExtResource("1")',
                  f'region = Rect2({i%4*SIZE[0]}, {i//4*SIZE[1]}, {SIZE[0]}, {SIZE[1]})', '']
    entries=[]
    for name,(indices,durations,loop) in clips.items():
        frame_entries=', '.join('{"duration": %.6f, "texture": SubResource("f%d")}' % (seconds,index)
                                for index,seconds in zip(indices,durations))
        entries.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 1.0}' % (frame_entries,str(loop).lower(),name))
    lines += ['[resource]', 'animations = [\n' + ',\n'.join(entries) + '\n]', '']
    (OUT/f'{key}.tres').write_text('\n'.join(lines),encoding='utf8')

def main():
    report={}
    for kind in ['hero','enemy']:
        for index in range(3):
            key=f'{kind}_{index}'
            path=OUT/f'{key}-source.png'
            image=Image.open(path).convert('RGBA')
            hero=kind=='hero'
            rows=6 if hero else (3 if index==1 else 4)
            alpha=image.getchannel('A')
            content_height=alpha.point(lambda p:255 if p>90 else 0).getbbox()[3]+1 if kind=='enemy' and index==1 else image.height
            content_height=min(image.height,content_height)
            groups,bounds=subjects(image,rows,content_height,hero)
            if hero and index==0:
                dedicated=Image.open(OUT/'hero_0-attack-source.png').convert('RGBA')
                attack_groups,_=subjects(dedicated,2)
                assert all(len(row)==4 for row in attack_groups), 'Invalid dedicated dwarf attack sheet'
                # This source family is at another resolution. Use one fixed scale
                # for all its attack poses, calibrated from the ready stance.
                attack_frames=[tile for row in attack_groups for tile in row]
                attack_reference=statistics.median([attack_frames[0].height,attack_frames[-1].height])
            assert all(len(group)==4 for r,group in enumerate(groups) if not (hero and index==0 and r in [3,4])), (key,[len(g) for g in groups])
            cells=[]
            for row in range(rows):
                for col in range(4):
                    own_scale=None
                    if hero and index==0 and row in [3,4]:
                        tile=attack_frames[(row-3)*4+col]
                        own_scale=185/attack_reference
                    else:
                        tile=groups[row][col]
                    box=tile.getchannel('A').point(lambda p:255 if p>70 else 0).getbbox()
                    if box is None: raise ValueError(f'Empty frame {key} {row} {col}')
                    anchor=hip_anchor(tile,box,hero)
                    cells.append((tile,box,anchor,own_scale))
            reference_height=statistics.median(box[3]-box[1] for _,box,_,_ in cells[:4 if hero else 2])
            target_height=([185,213,222] if hero else [192,188,222])[index]
            scale=target_height/reference_height
            # One scale for the WHOLE character, never independent per-frame scaling.
            frames=[]; boxes=[]
            atlas=Image.new('RGBA',(SIZE[0]*4,SIZE[1]*rows))
            for n,(tile,box,anchor,own_scale) in enumerate(cells):
                frame_scale=own_scale or scale
                cropped=tile.crop(box)
                cropped=cropped.resize((round(cropped.width*frame_scale),round(cropped.height*frame_scale)),Image.Resampling.LANCZOS)
                foot_lift=0
                if hero and 4<=n<12:
                    foot_lift=[0,1,3,6,0,1,3,6][n-4]
                frame=Image.new('RGBA',SIZE)
                left=round(PIVOT[0]-(anchor-box[0])*frame_scale)
                top=round(PIVOT[1]-foot_lift-cropped.height)
                if left<0 or left+cropped.width>SIZE[0] or top<0:
                    raise ValueError(f'Clipping {key}/{n}: {left},{top},{cropped.size}')
                frame.alpha_composite(cropped,(left,top))
                atlas.alpha_composite(frame,(n%4*SIZE[0],n//4*SIZE[1]))
                frames.append(frame)
                boxes.append(frame.getchannel('A').getbbox())
            atlas.save(OUT/f'{key}-atlas.png')
            if hero:
                attack_length=[.48,.36,.42][index]
                ranged_length=[.42,.30,.34][index]
                weights=[.12,.12,.10,.08,.13,.12,.16,.17]
                clips={
                  'idle':(list(range(4)),[.23]*4,True),
                  'run':(list(range(4,12)),[.065]*8,True),
                  'attack':(list(range(12,20)),[w*attack_length for w in weights],False),
                  'ranged':(list(range(20,24)),[w*ranged_length for w in [.22,.24,.19,.35]],False),
                  'special':([20,21,22,23],[.10,.10,.15,.15],False),
                  'guard':([20,21,20],[.36,.12,.36],True) if index==0 else ([0,1],[.3,.3],True),
                  'hurt':([17,18],[.11,.11],False),
                  'dodge':([7,8,9],[.06,.07,.06],False)}
            else:
                run=list(range(2,8)) if index==1 else list(range(2,10))
                attack=list(range(8,12)) if index==1 else list(range(10,16))
                attack_seconds=[.12,.12,.10,.18] if index==1 else [.09,.09,.07,.07,.10,.12]
                clips={
                  'idle':([0,1],[.34,.34],True),
                  'run':(run,[.10]*len(run),True),
                  'attack':(attack,attack_seconds,False),
                  'ranged':(attack,attack_seconds,False),
                  'windup':([attack[0],attack[1]],[.35,.35],False),
                  'hurt':([attack[-2],attack[-1]],[.10,.12],False)}
            write_resource(key,clips,len(frames))
            # Animated previews are derived from the normalized source frames.
            for clip in ['run','attack']:
                ids,durations,_=clips[clip]
                previews=[]
                for n in ids:
                    bg=Image.new('RGBA',SIZE,(22,36,45,255));d=ImageDraw.Draw(bg)
                    d.line((0,PIVOT[1],SIZE[0],PIVOT[1]),fill=(90,120,125,255))
                    bg.alpha_composite(frames[n]);previews.append(bg.convert('RGB'))
                previews[0].save(OUT/f'{key}-{clip}.gif',save_all=True,append_images=previews[1:],loop=0,
                                 duration=[max(20,round(s*1000)) for s in durations],disposal=2)
            report[key]={'source_size':list(image.size),'frame_count':len(frames),'canvas':SIZE,'pivot':PIVOT,
              'fixed_scale':scale,'row_bounds':bounds,'alpha':list(alpha.getextrema()),
              'distinct_frames':len(set(hashlib.sha256(f.tobytes()).hexdigest() for f in frames)),
              'clips':{name:{'frames':len(ids),'seconds':round(sum(d),4),'loop':loop} for name,(ids,d,loop) in clips.items()},
              'bounds':boxes}
            print(key,report[key]['frame_count'],'frames',report[key]['distinct_frames'],'distinct')
    (OUT/'qa.json').write_text(json.dumps(report,indent=2),encoding='utf8')

if __name__=='__main__':main()
