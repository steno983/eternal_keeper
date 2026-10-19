"""Validate all mission manifests and their referenced content, without dependencies."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate(root=ROOT):
    errors = []

    def fail(where, message):
        errors.append(f'{where}: {message}')

    def read(path):
        try:
            value = json.loads((root / path).read_text(encoding='utf-8-sig'))
            if not isinstance(value, dict):
                raise ValueError('serve un oggetto JSON')
            return value
        except (OSError, ValueError) as exc:
            fail(path, str(exc))
            return {}

    def number(value, where, minimum=0):
        ok = type(value) in (int, float) and value >= minimum
        if not ok:
            fail(where, f'serve un numero >= {minimum}')
        return ok

    def identifier(value, where):
        ok = isinstance(value, str) and re.fullmatch(r'[a-z0-9_]+', value)
        if not ok:
            fail(where, 'identificativo non valido (lettere minuscole, numeri, _)')
        return bool(ok)

    def reference(kind, value, where):
        if not identifier(value, where):
            return {}
        path = f'data/{kind}/{value}.json'
        obj = read(path)
        if obj.get('id') != value:
            fail(path, 'id diverso dal nome del file')
        if obj.get('schema_version') != 1:
            fail(path, 'schema_version deve essere 1')
        return obj

    def asset(path, where):
        if not isinstance(path, str) or not path.startswith('res://') or '..' in path.split('/') or not (root / path[6:]).is_file():
            fail(where, f'risorsa mancante/non valida: {path}')

    def pages(ids, available, where):
        if not isinstance(ids, list):
            fail(where, 'serve una lista di identificativi di intermezzi')
            return
        for page in ids:
            if page not in available:
                fail(where, f'intermezzo inesistente: {page}')

    def entrance(config, where):
        if not isinstance(config, dict):
            fail(where, 'serve un oggetto con style/write/hold/erase')
            return
        if config.get('style', 'pencil') not in ('pencil', 'ink', 'none'):
            fail(where, 'style: pencil, ink oppure none')
        for field in ('write', 'hold', 'erase'):
            if field in config:
                number(config[field], f'{where}.{field}', 0 if field == 'hold' else 0.01)

    roster = read('data/nemici/archetipi.json').get('roles', {})
    for role, stats in roster.items():
        if stats.get('kind') not in ('raider', 'archer', 'caster'):
            fail('data/nemici/archetipi.json', f'kind non supportato per {role}')
        for field in ('hp', 'speed', 'windup'):
            number(stats.get(field), f'archetipi.{role}.{field}', .01)
        if type(stats.get('visual')) is not int or stats['visual'] not in (0, 1, 2, 3):
            fail('data/nemici/archetipi.json', f'visual non valido per {role}')
    missions = sorted((root / 'data/missioni').glob('*.json'))
    active = read('data/campagna.json')
    if active.get('schema_version') != 1 or not identifier(active.get('mission'), 'data/campagna.json.mission') or not (root / 'data/missioni' / f'{active.get("mission")}.json').is_file():
        fail('data/campagna.json', 'missione attiva inesistente o versione non valida')
    if not missions:
        fail('data/missioni', 'nessuna missione')
    for path in missions:
        mid = path.stem
        m = reference('missioni', mid, str(path))
        entrance(m.get('entrance', {}), f'{mid}.entrance')
        if not identifier(m.get('texts'), f'{mid}.texts'):
            continue
        texts = read(f'data/testi/{m["texts"]}.json')
        available = [p.get('id') for p in texts.get('pages', [])]
        if len(set(available)) != len(available):
            fail(mid, 'identificativi degli intermezzi duplicati')
        pages(m.get('interludes_before'), available, f'{mid}.interludes_before')
        presentation = m.get('presentation', {})
        for field in ('reward_background', 'ending_background'):
            asset(presentation.get(field), f'{mid}.presentation.{field}')
        for page in texts.get('pages', []):
            if not all(isinstance(page.get(field), str) and page[field] for field in ('id', 'title', 'subtitle', 'art')):
                fail(mid, 'pagina: id/title/subtitle/art mancanti')
            beats = page.get('beats', [])
            if len(beats) != 3 or any(beat.get('hero') not in (0, 1, 2) or not isinstance(beat.get('text'), str) for beat in beats):
                fail(mid, 'pagina: servono tre battute con hero 0/1/2 e text')
            panels = presentation.get('comics', {}).get(page.get('art'), [])
            if len(panels) != 3:
                fail(mid, f'servono tre pannelli per {page.get("art")}')
            for panel in panels:
                asset(panel, f'{mid}.presentation.comics')
        if type(m.get('prologue')) is not bool:
            fail(mid, 'prologue deve essere true/false')
        if m.get('ending') != 'victory':
            fail(mid, 'ending supportato: victory')
        levels = m.get('levels', [])
        if not isinstance(levels, list) or not levels:
            fail(mid, 'levels deve contenere almeno un livello')
            continue
        if len(set(str(v) for v in levels)) != len(levels):
            fail(mid, 'levels contiene duplicati; usare ID distinti per stanze distinte')
        stage_rules = []
        for lid in levels:
            group = reference('livelli', lid, f'{mid}.levels')
            if not group:
                continue
            loc = f'data/livelli/{lid}.json'
            entrance(group.get('entrance', {}), loc + '.entrance')
            name = texts.get('levels', {}).get(group.get('text_id'), {}).get('name')
            if not isinstance(name, str) or not name.strip():
                fail(loc, 'titolo del livello mancante nei testi')
            for moment in ('before', 'after'):
                pages(group.get('interludes', {}).get(moment), available, f'{loc}.interludes.{moment}')
            stages = group.get('stages', [])
            if not isinstance(stages, list) or not stages:
                fail(loc, 'stages deve contenere almeno uno stage')
                continue
            if len(set(str(v) for v in stages)) != len(stages):
                fail(loc, 'identificativi stage duplicati nel livello')
            for index, sid in enumerate(stages):
                rule = reference('stage', sid, loc + '.stages')
                if not rule:
                    continue
                if 'reward' in rule or 'entrance' in rule:
                    fail(f'data/stage/{sid}.json', 'reward/entrance appartengono al livello, non allo stage')
                rule = dict(rule)
                rule['reward'] = group.get('reward', {}) if index == len(stages)-1 else {'type': 'none', 'choices': 3, 'heal': 0, 'mana': 0}
                stage_rules.append((sid, rule))
        upgrade_count = 0
        for lid, rule in stage_rules:
            where = f'data/stage/{lid}.json'
            kind = rule.get('type')
            if kind not in ('resistance', 'escape', 'synchronization', 'scrolling'):
                fail(where, f'tipo non supportato: {kind}')
            tid = rule.get('text_id')
            copy = texts.get('rooms', {}).get('stages', {}).get(tid, {})
            if not all(isinstance(copy.get(key), str) and copy[key].strip() for key in ('name', 'notice')):
                fail(where, f'text_id inesistente o incompleto: {tid}')
            interludes = rule.get('interludes', {})
            for moment in ('before', 'after'):
                pages(interludes.get(moment), available, f'{where}.interludes.{moment}')
            stage = rule.get('stage', {})
            for key in ('left', 'right', 'player_x'):
                number(stage.get(key), f'{where}.stage.{key}')
            left, right = stage.get('left', 0), stage.get('right', 0)
            if type(left) in (int, float) and type(right) in (int, float):
                if left >= right or not left <= stage.get('player_x', -1) <= right:
                    fail(where, 'limiti del livello/posizione iniziale incoerenti')
            number(rule.get('initial_enemies'), f'{where}.initial_enemies')
            if 'initial_roles' in rule and (not rule['initial_roles'] or any(role not in roster for role in rule['initial_roles'])):
                fail(where, 'initial_roles contiene ruoli non definiti')
            reinforcements = rule.get('reinforcements', {})
            for key in ('count', 'interval', 'max_alive'):
                number(reinforcements.get(key), f'{where}.reinforcements.{key}', 0.01 if key == 'interval' else 0)
            allies = rule.get('allies', {})
            for key in ('visible', 'echo_enabled'):
                if type(allies.get(key)) is not bool:
                    fail(where, f'allies.{key} deve essere true/false')
            for key in ('echo_interval', 'echo_max_x', 'echo_damage'):
                number(allies.get(key), f'{where}.allies.{key}', 0.01 if key == 'echo_interval' else 0)
            reward = rule.get('reward', {})
            if reward.get('type') == 'skill_upgrade':
                upgrade_count += 1
            if reward.get('type') not in ('none', 'skill_upgrade'):
                fail(where, 'reward.type: none oppure skill_upgrade')
            # Existing reward UI has three cards, not an arbitrary card count.
            if reward.get('choices') != 3:
                fail(where, 'reward.choices: la UI attuale supporta 3 scelte')
            for key in ('heal', 'mana'):
                number(reward.get(key), f'{where}.reward.{key}')
            if kind in ('defense', 'resistance'):
                number(rule.get('duration'), f'{where}.duration', 0.01)
            if 'spawn_points' in rule:
                if not isinstance(rule['spawn_points'], list) or not rule['spawn_points']:
                    fail(where, 'spawn_points richiede almeno un ingresso')
                for point in rule.get('spawn_points', []):
                    if point.get('lane') not in (0, 1, 2) or not left <= point.get('x', -1) <= right:
                        fail(where, 'spawn_points: posizione o corsia non valida')
                number(rule.get('spawn_safe_distance'), where + '.spawn_safe_distance', 1)
            if kind == 'synchronization':
                sync = rule.get('synchronization', {})
                for field in ('charge_seconds', 'radius', 'pulse_interval', 'pulse_warning', 'pulse_damage'):
                    number(sync.get(field), where + '.synchronization.' + field, 0.01)
                if sync.get('pulse_warning', 0) >= sync.get('pulse_interval', 0):
                    fail(where, 'pulse_warning deve essere minore di pulse_interval')
                if not sync.get('sigils'):
                    fail(where, 'synchronization richiede sigils')
                for sigil in sync.get('sigils', []):
                    if sigil.get('lane') not in (0, 1, 2) or not left <= sigil.get('x', -1) <= right:
                        fail(where, 'sigillo fuori dai limiti o corsia non valida')
            if kind == 'scrolling':
                number(rule.get('warning_time'), where + '.warning_time', .1)
                number(rule.get('spawn_distance'), where + '.spawn_distance', 440)
                encounters = rule.get('encounters', [])
                if not encounters: fail(where, 'scrolling richiede encounters')
                previous = left
                roles = read('data/nemici/archetipi.json').get('roles', {})
                for encounter in encounters:
                    at, gate = encounter.get('at_x', -1), encounter.get('gate_x', -1)
                    if not previous < at < gate < right:
                        fail(where, 'incontri non ordinati o gate fuori dal percorso')
                    previous = gate
                    if not encounter.get('entries'): fail(where, 'incontro senza ingressi')
                    for entry in encounter.get('entries', []):
                        if entry.get('archetype') not in roles or entry.get('side') not in (-1, 1) or entry.get('lane') not in (0, 1, 2):
                            fail(where, 'ingresso scrolling non valido')
                        number(entry.get('offset'), where + '.entry.offset')
            if kind in ('escape', 'scrolling', 'synchronization'):
                exit_rule = rule.get('exit', {})
                if exit_rule.get('lane') not in (-1, 0, 1, 2) or not left <= exit_rule.get('x', -1) <= right:
                    fail(where, 'uscita mancante o non valida')
            if kind == 'escape':
                exit_rule = rule.get('exit', {})
                for key in ('x', 'tolerance'):
                    number(exit_rule.get(key), f'{where}.exit.{key}', 0.01)
                if exit_rule.get('lane') not in (0, 1, 2):
                    fail(where, 'exit.lane deve essere 0, 1 o 2')
                if not left <= exit_rule.get('x', -1) <= right:
                    fail(where, 'uscita fuori dai limiti del livello')
                for key in ('spawn_min_distance', 'spawn_margin', 'spawn_spacing'):
                    number(rule.get(key), f'{where}.{key}')
            if kind == 'resistance':
                for key in ('anchor_x', 'warning_time', 'spawn_distance', 'entry_lane_hold'):
                    number(rule.get(key), f'{where}.{key}', 0.01)
                if not left <= rule.get('anchor_x', -1) <= right:
                    fail(where, 'anchor_x fuori dai limiti del livello')
                roles = rule.get('archetypes', {})
                for role, stats in roles.items():
                    if stats.get('kind') not in ('raider', 'archer', 'caster'):
                        fail(where, f'archetypes.{role}.kind non supportato')
                    for key in ('hp', 'speed', 'windup'):
                        number(stats.get(key), f'{where}.archetypes.{role}.{key}', 0.01)
                waves = rule.get('waves', [])
                if not waves:
                    fail(where, 'resistance richiede ondate')
                previous = -1
                for wave in waves:
                    if wave.get('id') not in texts.get('rooms', {}).get('wave_names', {}):
                        fail(where, f'nome ondata mancante: {wave.get("id")}')
                    at = wave.get('at', -1)
                    if number(at, f'{where}.waves.at'):
                        if at < previous:
                            fail(where, 'ondate non ordinate per at')
                        previous = at
                    for entry in wave.get('entries', []):
                        if entry.get('side') not in (-1, 1) or entry.get('lane') not in (0, 1, 2) or entry.get('archetype') not in roles:
                            fail(where, 'ingresso: side/lane/archetype non valido')
                        if number(entry.get('offset'), f'{where}.entry.offset') and number(at, f'{where}.wave.at'):
                            if at + entry['offset'] + rule.get('warning_time', 0) >= rule.get('duration', 0):
                                fail(where, 'ingresso previsto dopo la fine della resistenza')
            env = reference('ambienti', rule.get('environment'), where)
            if not env:
                continue
            asset(env.get('shader'), f'{where}.environment.shader')
            if not env.get('layers'):
                fail(where, 'ambiente privo di layers')
            for n, layer in enumerate(env.get('layers', [])):
                loc = f'data/ambienti/{env["id"]}.json.layers[{n}]'
                kind = layer.get('kind')
                if kind not in ('texture', 'pillars', 'tiles', 'arches'):
                    fail(loc, 'kind non supportato')
                asset(layer.get('texture'), loc)
                number(layer.get('depth'), loc + '.depth')
                if 'repeat_step' in layer:
                    number(layer['repeat_step'], loc + '.repeat_step', 1)
                if 'repeat_x' in layer and type(layer['repeat_x']) is not bool:
                    fail(loc, 'repeat_x deve essere true/false')
                alpha = layer.get('alpha', 1)
                if not number(alpha, loc + '.alpha') or alpha > 1:
                    fail(loc, 'alpha deve essere fra 0 e 1')
                for field in (['rect'] if kind in ('texture', 'tiles') else ['rect', 'region'] if kind == 'pillars' else ['region']):
                    value = layer.get(field)
                    if not isinstance(value, list) or len(value) != 4 or not all(type(v) in (int, float) for v in value) or min(value[2:]) <= 0:
                        fail(loc, f'{field}: servono [x,y,larghezza,altezza] con dimensioni positive')
                if kind in ('pillars', 'arches') and (not isinstance(layer.get('anchors'), list) or not all(type(a) in (int, float) for a in layer['anchors'])):
                    fail(loc, 'anchors deve essere una lista di numeri')
                if kind == 'tiles' and (not isinstance(layer.get('tiles'), list) or len(layer['tiles']) != 2 or not all(type(v) is int for v in layer['tiles']) or layer['tiles'][0] >= layer['tiles'][1]):
                    fail(loc, 'tiles richiede [inizio,fine_esclusa]')
        if upgrade_count > 4:
            fail(mid, 'le trasformazioni attuali supportano al massimo 4 ricompense skill_upgrade per run (una per magia)')
    return errors


if __name__ == '__main__':
    result = validate()
    print('\n'.join(result) if result else 'MISSIONI OK: livelli, ambienti, testi, intermezzi, ondate e risorse validi.')
    sys.exit(bool(result))
