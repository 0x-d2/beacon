// The catalog the collector writes (web/public/data/catalog.json) and the site reads: one zod schema, so a change to
// either side fails `npm run collect` instead of drawing a broken page (docs/beaconkit.md › Site).
import { z } from 'zod'

const localized = z.object({ tr: z.string(), en: z.string() })
const source = z.object({ file: z.string(), line: z.number() })
const colorValue = z.object({ hex: z.string(), alpha: z.number() })
const place = z.object({ file: z.string(), line: z.number(), code: z.string() })

export const usage = z.object({
  total: z.number(),
  files: z.number(),
  /** By area (`panel`, `settings`, `notch`, …; swift.ts › area). */
  byArea: z.record(z.string(), z.number()),
  places: z.array(z.object({ file: z.string(), line: z.number() })),
})

const literalKinds = z.enum(['radius', 'font', 'padding', 'spacing', 'frame', 'shadow', 'animation', 'color', 'material'])
const literalCounts = z.partialRecord(literalKinds, z.number())

/** A render of a variant or a surface, keyed `<language>-<theme>` (`tr-dark`): docs/beaconkit.md › Renders. */
/** `mode`: `screen` (the screen itself), `window` (the renderer's windows alone: materials flat), `imageRenderer`. */
const image = z.object({ src: z.string(), width: z.number(), height: z.number(), mode: z.string() })
const images = z.record(z.string(), image)

export const colorToken = z.object({
  id: z.string(),
  group: z.string(),
  doc: z.string(),
  expression: z.string(),
  values: z.object({ light: colorValue.nullable(), dark: colorValue.nullable(), lightHighContrast: colorValue.nullable(), darkHighContrast: colorValue.nullable() }),
  source,
  usage,
})

export const gradientToken = z.object({
  id: z.string(), group: z.string(), doc: z.string(), expression: z.string(), direction: z.string(),
  stops: z.object({ light: z.array(colorValue.nullable()), dark: z.array(colorValue.nullable()) }),
  source, usage,
})

export const textStyleToken = z.object({
  id: z.string(), size: z.number(), weight: z.string(), design: z.string(), tracking: z.number(), uppercase: z.boolean(),
  color: z.string().nullable(), doc: z.string(), source, usage,
})

export const metricToken = z.object({
  id: z.string(), group: z.string(), value: z.number().nullable(), island: z.number().nullable(), expression: z.string(),
  doc: z.string(), source, usage,
})

export const motionToken = z.object({
  id: z.string(), group: z.string(), kind: z.enum(['spring', 'seconds', 'number']), duration: z.number().nullable(),
  bounce: z.number().nullable(), value: z.number().nullable(), doc: z.string(), source, usage,
})

export const palette = z.object({
  id: z.string(), group: z.string(), property: z.string(), doc: z.string(), source,
  entries: z.array(z.object({ id: z.string(), expression: z.string(), value: colorValue.nullable() })),
})

export const landmark = z.object({ id: z.string(), title: localized, file: z.string(), value: z.number(), expression: z.string(), source, code: z.string() })

export const literalGroup = z.object({
  key: z.string(),
  value: z.number().nullable(),
  count: z.number(),
  files: z.number(),
  places: z.array(place),
  color: z.object({ light: colorValue.nullable(), dark: colorValue.nullable() }).nullable(),
  /** A token with the same value, said in both languages. */
  match: z.object({ token: z.string(), note: localized }).nullable(),
})

export const issue = z.object({ number: z.number(), title: z.string(), url: z.string(), item: z.string() })

export const variant = z.object({
  id: z.string(),
  title: z.string(),
  /** How the renderer photographed it: the screen (materials as drawn) or ImageRenderer (plain shapes only). */
  capture: z.enum(['screen', 'imageRenderer']),
  images,
})

export const component = z.object({
  id: z.string(),
  kind: z.enum(['view', 'modifier', 'style', 'shape', 'representable']),
  category: z.string(),
  source,
  doc: z.string(),
  api: z.array(z.object({ signature: z.string(), doc: z.string(), line: z.number() })),
  uses: z.object({ tokens: z.array(z.string()), components: z.array(z.string()) }),
  usedBy: z.array(z.string()),
  literals: literalCounts,
  usage,
  lastChange: z.string().nullable(),
  variants: z.array(variant),
  issues: z.array(issue),
})

export const surface = z.object({
  id: z.string(),
  group: z.enum(['panel', 'settings', 'notch', 'window']),
  case: z.string(),
  title: localized,
  symbol: z.string().nullable(),
  view: z.string(),
  source,
  doc: z.string(),
  components: z.record(z.string(), z.number()),
  tokens: z.record(z.string(), z.number()),
  literals: literalCounts,
  lastChange: z.string().nullable(),
  images,
  issues: z.array(issue),
})

export const guideEntry = z.object({
  id: z.string(), area: localized, what: localized, how: localized, file: z.string(), line: z.number().nullable(),
  code: z.string().nullable(), link: z.string().nullable(),
})

export const change = z.object({ sha: z.string(), at: z.string(), subject: z.string(), files: z.array(z.string()) })

/** When a group of renders was taken and at which commit (kit.sh's rendered.json); null before the first render. */
export const rendered = z.object({ sha: z.string(), at: z.string() }).nullable()

export const catalog = z.object({
  meta: z.object({
    sha: z.string(),
    branch: z.string(),
    dirty: z.boolean(),
    builtAt: z.string(),
    repo: z.string(),
    languages: z.array(z.string()),
    systemColors: z.string(),
    renders: z.object({ components: rendered, surfaces: rendered }),
    counts: z.object({ files: z.number(), uiFiles: z.number(), lines: z.number() }),
  }),
  categories: z.array(z.object({ id: z.string(), title: localized })),
  surfaceGroups: z.array(z.object({ id: z.string(), title: localized })),
  areas: z.record(z.string(), localized),
  tokens: z.object({
    colors: z.array(colorToken),
    gradients: z.array(gradientToken),
    textStyles: z.array(textStyleToken),
    metrics: z.array(metricToken),
    motions: z.array(motionToken),
    palettes: z.array(palette),
    landmarks: z.array(landmark),
  }),
  systemColors: z.array(z.object({ id: z.string(), light: colorValue, dark: colorValue, count: z.number() })),
  literals: z.record(literalKinds, z.array(literalGroup)),
  components: z.array(component),
  surfaces: z.array(surface),
  guide: z.array(guideEntry),
  changes: z.array(change),
  issues: z.array(issue),
})

export type Catalog = z.infer<typeof catalog>
export type Component = z.infer<typeof component>
export type Surface = z.infer<typeof surface>
export type Variant = z.infer<typeof variant>
export type ColorToken = z.infer<typeof colorToken>
export type GradientToken = z.infer<typeof gradientToken>
export type TextStyleToken = z.infer<typeof textStyleToken>
export type MetricToken = z.infer<typeof metricToken>
export type MotionToken = z.infer<typeof motionToken>
export type Palette = z.infer<typeof palette>
export type LiteralGroup = z.infer<typeof literalGroup>
export type LiteralKind = z.infer<typeof literalKinds>
export type Usage = z.infer<typeof usage>
export type Issue = z.infer<typeof issue>
export type GuideEntry = z.infer<typeof guideEntry>
export type Rendered = z.infer<typeof rendered>
