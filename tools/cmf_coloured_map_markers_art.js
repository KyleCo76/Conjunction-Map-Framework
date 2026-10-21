// Render the Coloured Map Markers adapter's art from the mod's own Shape icons (developer only).
//
//   node tools/cmf_coloured_map_markers_art.js <Shape (Worldmap)/shapes folder> [out folder]
//
// The input is the "Shape (Worldmap)" folder of "CMM Shapes - Remastered 938 1.60" from Coloured Map Markers'
// misc files on Nexus (mod 938): DJ_Kovrik's recoloured shapes, shared by the maintainer LewisElementary for
// other mods to use with credit to DJ_Kovrik and the mod (sticky post "About Compatiblity!", 2026-10-12).
// Each SVG is named by the shape's character id in the 5.01 panel_worldmap movie; SHAPES below says which pin
// type's glyph (PinIcon_122, sprite 588) draws each id, read from the movie's frame labels. The pictures are
// not changed: each is drawn centred into 96x96 with the outer 4 pixels left clear, and tools/cmf_pack.py cooks
// them into the adapter's own content/texture.cache. Needs Node with Playwright and Chromium.
const fs = require('fs');
const path = require('path');

// pin type -> shape id; level variants (_1 to _3) take the base type's image (API version 1 keys on the base).
const SHAPES = {
	Boat: 362, Horse: 363, Shopkeeper: 364, Blacksmith: 365, Armorer: 366, Hairdresser: 368, Alchemic: 369,
	Enchanter: 370, PlayerStash: 374, PlayerStashDiscoverable: 374, Entrance: 375, MonsterNest: 376,
	MonsterNestDisabled: 391, PlaceOfPower: 393, PlaceOfPowerDisabled: 394, MagicLamp: 400, Herbalist: 401,
	TreasureHuntMappin: 409, TreasureHuntMappinDisabled: 424, Whetstone: 428, ArmorRepairTable: 429,
	GrindStone: 431, Prostitute: 435, Innkeeper: 444, SpoilsOfWar: 457, SpoilsOfWarDisabled: 458,
	BanditCamp: 459, BanditCampDisabled: 471, BanditCampfire: 472, BanditCampfireDisabled: 473,
	BossAndTreasure: 474, BossAndTreasureDisabled: 486, Contraband: 487, ContrabandDisabled: 488,
	ContrabandShip: 489, ContrabandShipDisabled: 490, RescuingTown: 491, RescuingTownDisabled: 509,
	DungeonCrawl: 510, DungeonCrawlDisabled: 511, Hideout: 512, HideoutDisabled: 514, Archmaster: 520,
	InfestedVineyard: 522, InfestedVineyardDisabled: 526, WineMerchant: 527, DyeMerchant: 529, Plegmund: 533,
	PlegmundDisabled: 535, WineContract: 536, WineContractDisabled: 537, SignalingStake: 539,
	SignalingStakeDisabled: 540, Stables: 541, Bed: 543, MutagenDismantle: 545, AlchemyTable: 546,
	Bookshelf: 550, KnightErrant: 552, KnightErrantDisabled: 554, Cammerlengo: 556,
};
const SIZE = 96, MARGIN = 4, SUPER = 4;

// PlayerStash and PlayerStashDiscoverable share one image.
const fileFor = type => (type === 'PlayerStashDiscoverable' ? 'PlayerStash' : type)
	.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase() + '.png';

async function main() {
	const [shapes, out = 'source/adapters/coloured-map-markers/modCMFAdapterColouredMapMarkers/art'] = process.argv.slice(2);
	if (!shapes) throw new Error('usage: node tools/cmf_coloured_map_markers_art.js <shapes folder> [out folder]');
	const { chromium } = require('playwright');
	const browser = await chromium.launch(fs.existsSync('/opt/pw-browsers/chromium')
		? { executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' } : {});
	const page = await browser.newPage();
	// The SVGs are drawn as images (no scripts run); refuse any request that is not the image itself.
	await page.route('**/*', r => (/^(data:|about:)/.test(r.request().url()) ? r.continue() : r.abort()));
	fs.mkdirSync(out, { recursive: true });
	const done = new Set();
	for (const [type, id] of Object.entries(SHAPES)) {
		const name = fileFor(type);
		if (done.has(name)) continue;
		done.add(name);
		const svg = fs.readFileSync(path.join(shapes, id + '.svg'));
		const png = await page.evaluate(async ({ url, size, margin, sup }) => {
			const img = new Image();
			img.src = url;
			await img.decode();
			const w = img.naturalWidth, h = img.naturalHeight, k = (size - 2 * margin) * sup / Math.max(w, h);
			const big = document.createElement('canvas');
			big.width = big.height = size * sup;
			big.getContext('2d').drawImage(img, (size * sup - w * k) / 2, (size * sup - h * k) / 2, w * k, h * k);
			const small = document.createElement('canvas');
			small.width = small.height = size;
			const g = small.getContext('2d');
			g.imageSmoothingQuality = 'high';
			g.drawImage(big, 0, 0, size, size);
			return small.toDataURL('image/png').split(',')[1];
		}, { url: 'data:image/svg+xml;base64,' + svg.toString('base64'), size: SIZE, margin: MARGIN, sup: SUPER });
		fs.writeFileSync(path.join(out, name), Buffer.from(png, 'base64'));
		console.log(type, id, name);
	}
	await browser.close();
}

if (require.main === module) main().catch(e => { console.error(e.message); process.exit(1); });
module.exports = { SHAPES, fileFor };
