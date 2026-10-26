// The cardboard figures from design/source/figures, by file name.
import amor from '../../../design/source/figures/amor.png';
import beschuetzer from '../../../design/source/figures/beschuetzer.png';
import dorfbewohner from '../../../design/source/figures/dorfbewohner.png';
import faehrtenleger from '../../../design/source/figures/faehrtenleger.png';
import hexe from '../../../design/source/figures/hexe.png';
import jaeger from '../../../design/source/figures/jaeger.png';
import lauscherin from '../../../design/source/figures/lauscherin.png';
import magd from '../../../design/source/figures/magd.png';
import seherin from '../../../design/source/figures/seherin.png';
import stillePfote from '../../../design/source/figures/stille_pfote.png';
import werwolf from '../../../design/source/figures/werwolf.png';

export const figures = {
  amor,
  beschuetzer,
  dorfbewohner,
  faehrtenleger,
  hexe,
  jaeger,
  lauscherin,
  magd,
  seherin,
  stille_pfote: stillePfote,
  werwolf,
} satisfies Record<string, ImageMetadata>;

export type Figure = keyof typeof figures;
