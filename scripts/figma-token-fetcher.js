#!/usr/bin/env node
// Figma Variables API → structured token data
// Zero-dependency Node.js module
// Fetches all variables from the Figma Core Theme file and returns
// structured data matching the format expected by generate-tokens.js
//
// Source of truth: Figma file D0hIZP7fHnn37d8EfXGJoM (Core — Theme)
// API docs: https://www.figma.com/developers/api#variables

const https = require('https');

const FILE_KEY = 'D0hIZP7fHnn37d8EfXGJoM';
const REQUEST_TIMEOUT_MS = 15000;
const MAX_RESPONSE_BYTES = 50 * 1024 * 1024; // 50 MB

// Collection IDs (from Figma file)
const COLLECTION_IDS = {
    primitives: 'VariableCollectionId:2006:223',
    colour: 'VariableCollectionId:2006:221',
    space: 'VariableCollectionId:5030:11499',
    borders: 'VariableCollectionId:5030:11344',
    fonts: 'VariableCollectionId:5510:123',
};

// Swift identifier allowlist — reject anything that could inject code
const SWIFT_IDENTIFIER_RE = /^[a-zA-Z][a-zA-Z0-9]*$/;

function assertValidIdentifier(name, context) {
    if (!SWIFT_IDENTIFIER_RE.test(name)) {
        throw new Error(
            `Invalid identifier "${name}" from ${context} — ` +
            'must match /^[a-zA-Z][a-zA-Z0-9]*$/. ' +
            'This may indicate a malformed Figma variable name.'
        );
    }
}

// ─── HTTP fetch ─────────────────────────────────────────────────────────────

function fetchFigmaVariables(token) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.figma.com',
            path: `/v1/files/${FILE_KEY}/variables/local`,
            headers: { 'X-FIGMA-TOKEN': token },
            rejectUnauthorized: true,
        };
        const req = https.get(options, (res) => {
            let data = '';
            let bytes = 0;
            res.on('data', (chunk) => {
                bytes += chunk.length;
                if (bytes > MAX_RESPONSE_BYTES) {
                    req.destroy(new Error(`Figma API response exceeded ${MAX_RESPONSE_BYTES} bytes`));
                    return;
                }
                data += chunk;
            });
            res.on('end', () => {
                if (res.statusCode !== 200) {
                    reject(new Error(`Figma API returned status ${res.statusCode}`));
                    return;
                }
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error(`Failed to parse Figma response: ${e.message}`));
                }
            });
            res.on('error', reject);
        });
        req.on('error', reject);
        req.setTimeout(REQUEST_TIMEOUT_MS, () => {
            req.destroy(new Error(`Figma API request timed out after ${REQUEST_TIMEOUT_MS}ms`));
        });
    });
}

// ─── Alias resolution ───────────────────────────────────────────────────────

function resolveValue(value, allVariables, visited = new Set()) {
    if (value && typeof value === 'object' && value.type === 'VARIABLE_ALIAS') {
        if (visited.has(value.id)) {
            console.warn(`[warn] Circular alias detected at variable ID ${value.id} — skipping`);
            return null;
        }
        visited.add(value.id);
        const target = allVariables[value.id];
        if (!target) return null; // remote/external alias — skip
        const modes = Object.keys(target.valuesByMode);
        return resolveValue(target.valuesByMode[modes[0]], allVariables, visited);
    }
    return value;
}

function resolveValueForMode(value, modeId, allVariables, visited = new Set()) {
    if (value && typeof value === 'object' && value.type === 'VARIABLE_ALIAS') {
        if (visited.has(value.id)) {
            console.warn(`[warn] Circular alias detected at variable ID ${value.id} — skipping`);
            return null;
        }
        visited.add(value.id);
        const target = allVariables[value.id];
        if (!target) return null; // remote/external alias — skip
        const targetModes = Object.keys(target.valuesByMode);
        const targetModeId = targetModes.includes(modeId) ? modeId : targetModes[0];
        return resolveValueForMode(target.valuesByMode[targetModeId], targetModeId, allVariables, visited);
    }
    return value;
}

// ─── Color conversion ───────────────────────────────────────────────────────

function figmaColorToHex(color) {
    if (!color || typeof color.r !== 'number') {
        throw new Error(`figmaColorToHex received invalid color: ${JSON.stringify(color)}`);
    }
    const r = Math.round(color.r * 255);
    const g = Math.round(color.g * 255);
    const b = Math.round(color.b * 255);
    const hex = ((r << 16) | (g << 8) | b).toString(16).padStart(6, '0').toUpperCase();
    // Round alpha to avoid floating point artifacts (e.g. 0.10000000149011612 → 0.1)
    const a = color.a !== undefined ? parseFloat(color.a.toPrecision(4)) : 1;
    if (a < 1) {
        return `rgba(${r}, ${g}, ${b}, ${a})`;
    }
    return `#${hex}`;
}

// ─── Collection helpers ─────────────────────────────────────────────────────

function getVariablesInCollection(collectionId, allVariables) {
    return Object.values(allVariables).filter(
        (v) => v.variableCollectionId === collectionId
    );
}

function getModeIds(collectionId, collections) {
    const col = collections[collectionId];
    if (!col) return {};
    const result = {};
    for (const mode of col.modes) {
        result[mode.name] = mode.modeId;
    }
    return result;
}

function validateCollections(collections) {
    for (const [name, id] of Object.entries(COLLECTION_IDS)) {
        if (!collections[id]) {
            console.warn(`[warn] Expected Figma collection "${name}" (${id}) not found — tokens in this category will be empty`);
        }
    }
}

// ─── Build palette (Primitives collection) ──────────────────────────────────

function buildPalette(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.primitives, allVariables);
    const palette = {};

    for (const v of vars) {
        if (v.resolvedType !== 'COLOR') continue;
        // Name format: "Palette/Blue/50"
        const parts = v.name.split('/');
        if (parts[0] !== 'Palette' || parts.length !== 3) continue;

        // Convert to camelCase: "BlackTint" → "blackTint", "Black Tint" → "blackTint"
        const camelName = parts[1]
            .split(/\s+/)
            .map((word, i) => i === 0
                ? word.charAt(0).toLowerCase() + word.slice(1)
                : word.charAt(0).toUpperCase() + word.slice(1))
            .join('');
        const shade = parts[2];

        if (!palette[camelName]) palette[camelName] = {};
        const modeId = Object.keys(v.valuesByMode)[0];
        const resolved = resolveValue(v.valuesByMode[modeId], allVariables);
        if (!resolved) continue;
        palette[camelName][shade] = figmaColorToHex(resolved);
    }

    return palette;
}

// ─── Build sizing (Primitives collection — FLOAT type) ──────────────────────

function buildSizing(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.primitives, allVariables);
    const sizing = { scale: {}, opacity: {}, borderRadius: {}, borderWidth: {}, space: { default: {} }, fontFamily: {}, fontSize: {}, fontWeight: {}, lineHeight: {} };

    for (const v of vars) {
        if (v.resolvedType !== 'FLOAT') continue;
        const modeId = Object.keys(v.valuesByMode)[0];
        const resolved = resolveValue(v.valuesByMode[modeId], allVariables);
        if (resolved === null) continue;
        const parts = v.name.split('/');

        if (parts[0] === 'Scale' && parts.length === 2) {
            sizing.scale[parts[1]] = resolved;
        } else if (parts[0] === 'Opacity' && parts.length === 2) {
            sizing.opacity[parts[1]] = resolved;
        } else if (parts[0] === 'Border Radius' && parts.length === 2) {
            sizing.borderRadius[parts[1]] = resolved;
        } else if (parts[0] === 'Border Width' && parts.length === 2) {
            sizing.borderWidth[parts[1]] = resolved;
        }
    }

    return sizing;
}

// ─── Build semantic colors (Colour collection) ─────────────────────────────

function buildSemanticColors(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.colour, allVariables);
    const modes = getModeIds(COLLECTION_IDS.colour, collections);
    const lightModeId = modes['Light'];
    const darkModeId = modes['Dark'];

    const semantic = {};

    for (const v of vars) {
        if (v.resolvedType !== 'COLOR') continue;
        // Name format: "Primary/Resting", "Content/Text/Default", "Status/Error/Resting"
        const parts = v.name.split('/');
        if (parts.length < 2) continue;

        const lightVal = resolveValueForMode(v.valuesByMode[lightModeId], lightModeId, allVariables);
        const darkVal = resolveValueForMode(v.valuesByMode[darkModeId], darkModeId, allVariables);

        // Skip if either mode can't be resolved (remote alias)
        if (!lightVal || !darkVal) continue;

        const lightHex = figmaColorToHex(lightVal);
        const darkHex = figmaColorToHex(darkVal);

        // Build nested structure — validate each key as a Swift identifier
        const keys = parts.map((p) => p.charAt(0).toLowerCase() + p.slice(1));
        for (const key of keys) {
            assertValidIdentifier(key, `Colour variable "${v.name}"`);
        }

        let obj = semantic;
        for (let i = 0; i < keys.length - 1; i++) {
            if (!obj[keys[i]]) obj[keys[i]] = {};
            obj = obj[keys[i]];
        }
        const leaf = keys[keys.length - 1];
        obj[leaf] = {
            light: { value: lightHex, type: 'color' },
            dark: { value: darkHex, type: 'color' },
        };
    }

    return semantic;
}

// ─── Build spacing (Space collection) ───────────────────────────────────────

function buildSpacing(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.space, allVariables);
    const spacing = { space: {} };

    for (const v of vars) {
        if (v.resolvedType !== 'FLOAT') continue;
        const modeId = Object.keys(v.valuesByMode)[0];
        const resolved = resolveValue(v.valuesByMode[modeId], allVariables);
        if (resolved === null) continue;
        // Name format: "0", "10", "20", etc.
        spacing.space[v.name] = { default: { value: resolved } };
    }

    return spacing;
}

// ─── Build borders (Borders collection) ─────────────────────────────────────

function buildBorders(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.borders, allVariables);
    const borders = { radius: {} };

    for (const v of vars) {
        if (v.resolvedType !== 'FLOAT') continue;
        const modeId = Object.keys(v.valuesByMode)[0];
        const resolved = resolveValue(v.valuesByMode[modeId], allVariables);
        if (resolved === null) continue;
        // Name format: "Radius/Default", "Radius/0", "Radius/10"
        const parts = v.name.split('/');
        if (parts[0] === 'Radius' && parts.length === 2) {
            const key = parts[1].toLowerCase();
            borders.radius[key] = { value: resolved };
        }
    }

    return borders;
}

// ─── Build fonts (Fonts collection) ──────────────────────────────────────────

function buildFonts(allVariables, collections) {
    const vars = getVariablesInCollection(COLLECTION_IDS.fonts, allVariables);
    const fonts = { fontFamily: {}, fontSize: {}, fontWeight: {}, lineHeight: {} };

    for (const v of vars) {
        const modeId = Object.keys(v.valuesByMode)[0];
        const resolved = resolveValue(v.valuesByMode[modeId], allVariables);
        if (resolved === null) continue;
        const parts = v.name.split('/');

        if (parts[0] === 'Font Family' && parts.length === 2) {
            fonts.fontFamily[parts[1].toLowerCase()] = resolved;
        } else if (parts[0] === 'Font Size' && parts.length === 2) {
            fonts.fontSize[parts[1]] = resolved;
        } else if (parts[0] === 'Font Weight' && parts.length === 2) {
            fonts.fontWeight[parts[1]] = resolved;
        } else if (parts[0] === 'Line Height' && parts.length === 2) {
            fonts.lineHeight[parts[1]] = resolved;
        }
    }

    return fonts;
}

// ─── Main export ────────────────────────────────────────────────────────────

async function fetchTokens(figmaToken) {
    if (!figmaToken) {
        throw new Error(
            'FIGMA_TOKEN environment variable is required.\n' +
            'Set it locally: export FIGMA_TOKEN=figd_...\n' +
            'In CI: add FIGMA_TOKEN as a GitHub Actions secret.'
        );
    }

    const response = await fetchFigmaVariables(figmaToken);

    if (!response.meta || !response.meta.variables) {
        throw new Error(
            'Unexpected Figma API response — missing meta.variables. ' +
            'This may indicate a permissions error or an API change.'
        );
    }

    const { variables: allVariables, variableCollections: collections } = response.meta;
    validateCollections(collections);

    return {
        palette: buildPalette(allVariables, collections),
        sizing: buildSizing(allVariables, collections),
        semanticColor: buildSemanticColors(allVariables, collections),
        spacing: buildSpacing(allVariables, collections),
        borders: buildBorders(allVariables, collections),
        fonts: buildFonts(allVariables, collections),
    };
}

module.exports = { fetchTokens };
