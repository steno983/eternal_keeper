"""Check editable copy without generating or modifying any story text."""
from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def read(path):
    try: return json.loads(path.read_text(encoding='utf-8-sig'))
    except (ValueError,OSError) as exc:
        errors.append(f'{path.relative_to(ROOT)}: {exc}')
        return {}
def require(condition,message):
    if not condition: errors.append(message)
data={name:read(ROOT/'data/testi'/f'{name}.json') for name in ('capitolo_01','ponte','abilita','interfaccia')}
chapter=data['capitolo_01']
intro=chapter.get('intro',{})
require(isinstance(intro.get('title'),str),'intro.title: titolo mancante')
require(isinstance(intro.get('kicker'),str),'intro.kicker: testo mancante')
require(isinstance(intro.get('paragraphs'),list) and bool(intro['paragraphs']) and all(isinstance(p,str) and p.strip() for p in intro['paragraphs']),'intro.paragraphs: servono paragrafi non vuoti')
pages=chapter.get('pages',[])
require(bool(pages),'capitolo_01.pages: serve almeno una pagina')
for i,page in enumerate(pages):
    require(isinstance(page.get('art'),str) and bool(page['art']),f'pagina {i+1}: identificativo immagine mancante')
    require(all(isinstance(page.get(k),str) for k in ('id','title','subtitle')),f'pagina {i+1}: intestazioni mancanti')
    beats=page.get('beats',[])
    require(len(beats)==3,f'pagina {i+1}: servono tre battute')
    for j,beat in enumerate(beats):
        require(beat.get('hero') in (0,1,2) and isinstance(beat.get('text'),str),f'pagina {i+1}, battuta {j+1}: hero/text non valido')
for lid,copy in chapter.get('rooms',{}).get('stages',{}).items():
    require(all(isinstance(copy.get(key),str) and copy[key].strip() for key in ('name','notice')),f'rooms.stages.{lid}: name/notice mancanti')
for key,count in (('heroes',3),('spell_names',4),('spell_descriptions',4),('upgrades',12)):
    require(len(data['abilita'].get(key,[]))==count,f'abilita.{key}: servono {count} elementi')
expected={'orb':0,'pierce':0,'fan':0,'ash':1,'sanctuary':1,'eruption':1,'mirror':2,'renewal':2,'aegis':2,'judgment':3,'inferno':3,'nova':3}
require({u.get('id'):u.get('slot') for u in data['abilita'].get('upgrades',[])}==expected,'Potenziamenti: mantenere id e slot originali')
paths=data['abilita'].get('build_paths',{})
require(set(paths)=={'fire','ward','control'},'build_paths: servono Braci, Custode e Sigilli')
for upgrade in data['abilita'].get('upgrades',[]):
    require(upgrade.get('path') in paths,f'Percorso mancante: {upgrade.get("id")}')
for key,path in paths.items():
    require(all(isinstance(path.get(field),str) and path[field] for field in ('name','color','style','trait')),f'Percorso {key}: testi mancanti')
    for stat in ('duration','barrier','slow'):
        if stat in path:
            require(len(path[stat])==2 and all(isinstance(v,(int,float)) and v>0 for v in path[stat]),f'Percorso {key}: due valori positivi per {stat}')
for field in ('titles','tails','beats'):
    require(len(data['ponte'].get(field,[]))==3,f'ponte.{field}: servono tre pagine')
ui=data['interfaccia']
require(all(isinstance(v,str) for v in ui.values()),'interfaccia: tutti i valori devono essere stringhe')
mission=read(ROOT/'data/missioni/archivio.json')
groups=[read(ROOT/'data/livelli'/f'{level_id}.json') for level_id in mission.get('levels',[])]
rooms=[read(ROOT/'data/stage'/f'{stage_id}.json') for group in groups for stage_id in group.get('stages',[])]
for room in rooms:
    if room.get('type')!='resistance': continue
    for role in room.get('archetypes',{}):
        require('entry_'+role in ui,f'interfaccia: manca il nome del ruolo {role}')
    for wave in room.get('waves',[]):
        require(wave.get('id') in chapter.get('rooms',{}).get('wave_names',{}),f'capitolo_01.rooms.wave_names: manca il nome dell’ondata {wave.get("id")}')
        for entry in wave.get('entries',[]):
            require(entry.get('side') in (-1,1) and entry.get('lane') in (0,1,2),'Ingresso: side/lane non valido')
            require(entry.get('archetype') in room.get('archetypes',{}),'Ingresso: ruolo non definito')
for path in (ROOT/'scripts').glob('*.gd'):
    for key in re.findall(r'Texts\.ui\("([^"]+)"\)',path.read_text(encoding='utf-8')):
        require(key in ui,f'{path.name}: testo mancante in interfaccia.json: {key}')
contracts=read(ROOT/'tools/text_formats.json')
for section,mapping in contracts.items():
    target=ui if section=='interfaccia' else chapter.get('rooms',{})
    for key,expected_format in mapping.items():
        actual=re.findall(r'%(?:0?\d+)?(?:\.\d+)?[dfs%]',str(target.get(key,'')))
        require(actual==expected_format,f'{section}.{key}: mantenere i segnaposto {expected_format}')
if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'TESTI OK: quattro JSON validi, {len(pages)} pagine, {len(intro["paragraphs"])} paragrafi introduttivi, {len(ui)} testi di interfaccia.')
