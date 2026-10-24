// Execute the actual checked-in page script, with no packages or network access.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const page = path.join(__dirname, '../source/adapter-check/page/index.html');
function load() {
    assert.ok(fs.existsSync(page), 'generated offline page is missing');
    const html = fs.readFileSync(page, 'utf8');
    const script = html.match(/<script id="cmf-page-script">([\s\S]*?)<\/script>/)[1];
    const context = { module: { exports: {} } };
    vm.runInNewContext(script, context);
    return { ...context.module.exports, html };
}
function results(text, rows) { return JSON.parse(JSON.stringify(load().matchMods(text, rows || load().entries))); }
function names(text, rows) { return results(text, rows).map(r => r.entry.name); }
test('adapter-only folders and download names never imply source mod', () => {
    for (const text of ['modCMFAdapterMapQuestInsight', 'CMF Adapter - Map Quest Insight',
                        'CMF Adapter - Fog of War 1.0.1.zip', 'MODCMFADAPTERBOTANIST']) {
        assert.deepEqual(results(text), []);
    }
});
test('case, CRLF and disabled entries remain name findings', () => {
    assert.deepEqual(names('[MODMAPQUESTINSIGHT]\r\nEnabled=0'), ['Map Quest Insight']);
    assert.deepEqual(names('-Fog of War\r\n+Witcher Gear Map'), ['Witcher Gear Map', 'Fog of War']);
});
test('folder, quoted path and manager display names match bounded tokens', () => {
    for (const text of ['"C:\\Games\\Mods\\modMapQuestInsight"', '/home/me/Mods/modMapQuestInsight/',
                        'Map Quest Insight-14219-1-6-2.zip', '+Map Quest Insight', '"Map Quest Insight"']) {
        assert.deepEqual(names(text), ['Map Quest Insight'], text);
    }
});
test('source plus adapter found is qualified without inferring version', () => {
    const result = results('modMapQuestInsight modCMFAdapterMapQuestInsight');
    assert.equal(result.length, 1);
    assert.equal(result[0].adapterFound, true);
    assert.deepEqual(names('Map Quest Insight\nCMF Adapter - Map Quest Insight'), ['Map Quest Insight']);
    assert.equal(results('Map Quest Insight\nCMF Adapter - Map Quest Insight')[0].adapterFound, true);
});
test('duplicates collapse and unknown/HTML input yields no results', () => {
    assert.equal(results('modMapQuestInsight\nMODMAPQUESTINSIGHT\nMap Quest Insight').length, 1);
    for (const text of ['', '  \r\n', 'unlisted_mod', '<script>alert(1)</script>']) assert.deepEqual(results(text), []);
});
test('token boundaries reject suffixes, prefixes and underscores', () => {
    for (const text of ['xmodMapQuestInsight', 'modMapQuestInsightExtra', 'modMapQuestInsight_extra',
                        'xMap Quest Insight', 'Map Quest Insights']) assert.deepEqual(results(text), [], text);
});
test('longer overlapping names do not report a contained short name', () => {
    const base = {folders: [], adapter: null, status: 'works'};
    const rows = [{...base, name: 'Map'}, {...base, name: 'Map Plus'}, {...base, name: 'Other Map'}];
    assert.deepEqual(names('Map Plus\nOther Map', rows), ['Map Plus', 'Other Map']);
    assert.deepEqual(names('Map Plus\nMap', rows), ['Map', 'Map Plus']);
});
test('Ink and Iron variants and external tool exact name work', () => {
    assert.deepEqual(names('modInkAndIron\nmodInkAndIronUI'), ['Ink and Iron']);
    assert.deepEqual(names('World Map Merger'), ['World Map Merger']);
    assert.deepEqual(names('World Map Mergers'), []);
});
test('page uses safe DOM text and has no network loading primitives', () => {
    const {html} = load();
    assert.ok(!/innerHTML|outerHTML|insertAdjacentHTML|document\.write|fetch\s*\(|XMLHttpRequest|\bimport\s/.test(html));
    assert.ok(!/<(?:script|link|iframe|img)\b[^>]*(?:src|href)\s*=/i.test(html));
    assert.match(html, /textContent/);
    assert.match(html, /Enabled=0/);
    assert.match(html, /cmd \/c dir \/b \/ad/);
    assert.match(html, /names found in pasted text/i);
});

class Element {
    constructor(tag) { this.tag = tag; this.children = []; this.textContent = ""; }
    appendChild(child) { this.children.push(child); }
    replaceChildren() { this.children = []; }
    set innerHTML(value) { throw new Error("unsafe HTML sink"); }
}
function textOf(element) { return element.textContent + element.children.map(textOf).join(" "); }
function descendants(element) { return element.children.flatMap(child => [child, ...descendants(child)]); }
test('actual renderer shows recommendations and never renders pasted HTML', () => {
    const {renderResults, entries} = load();
    const container = new Element('div');
    const document = {createElement: tag => new Element(tag)};
    renderResults('<img src=x onerror=alert(1)>modMapQuestInsight', entries, container, document);
    assert.deepEqual(descendants(container).filter(e => e.tag === 'h3').map(e => e.textContent), ['Map Quest Insight']);
    assert.match(textOf(container), /install or update CMF Adapter - Map Quest Insight \(version 1\.1\.1 or newer\)/);
    assert.ok(!textOf(container).includes('onerror'));
    assert.ok(!descendants(container).some(e => e.tag === 'img' || e.tag === 'script'));
    renderResults('modMapQuestInsight modCMFAdapterMapQuestInsight', entries, container, document);
    assert.match(textOf(container), /cannot confirm that it is enabled/);
    assert.match(textOf(container), /Recommended minimum adapter download: 1\.1\.1/);
});
test('actual renderer gives external tool no invented links and replaces prior findings', () => {
    const {renderResults, entries} = load();
    const container = new Element('div');
    const document = {createElement: tag => new Element(tag)};
    renderResults('World Map Merger', entries, container, document);
    assert.match(textOf(container), /Incompatible by design/);
    assert.equal(descendants(container).filter(e => e.tag === 'a').length, 0);
    renderResults('', entries, container, document);
    assert.equal(container.children.length, 1);
    assert.equal(textOf(container), 'No known mod names found in pasted text.');
});
