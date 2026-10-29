// The cardboard figures from design/source/figures, by file name.
import amor from '../../../design/source/figures/amor.png';
import dorfbewohner from '../../../design/source/figures/dorfbewohner.png';
import faehrtenleger from '../../../design/source/figures/faehrtenleger.png';
import hexe from '../../../design/source/figures/hexe.png';
import jaeger from '../../../design/source/figures/jaeger.png';
import lauscherin from '../../../design/source/figures/lauscherin.png';
import magd from '../../../design/source/figures/magd.png';
import seherin from '../../../design/source/figures/seherin.png';
import stillePfote from '../../../design/source/figures/stille_pfote.png';
import werwolf from '../../../design/source/figures/werwolf.png';
import schaefer from '../../../design/source/figures/schaefer.png';
import waescherin from '../../../design/source/figures/waescherin.png';
import zimmermann from '../../../design/source/figures/zimmermann.png';
import spinnerin from '../../../design/source/figures/spinnerin.png';
import schuster from '../../../design/source/figures/schuster.png';
import blumenmaedchen from '../../../design/source/figures/blumenmaedchen.png';
import tueftler from '../../../design/source/figures/tueftler.png';
import grossmutter from '../../../design/source/figures/grossmutter.png';
import grossvater from '../../../design/source/figures/grossvater.png';
import baeckerin from '../../../design/source/figures/baeckerin.png';
import fischerin from '../../../design/source/figures/fischerin.png';
import schneiderin from '../../../design/source/figures/schneiderin.png';
import gaensehirtin from '../../../design/source/figures/gaensehirtin.png';
import wirtin from '../../../design/source/figures/wirtin.png';
import schmied from '../../../design/source/figures/schmied.png';
import mueller from '../../../design/source/figures/mueller.png';
import spielmann from '../../../design/source/figures/spielmann.png';
import imker from '../../../design/source/figures/imker.png';

export const figures = {
  amor,
  dorfbewohner,
  faehrtenleger,
  hexe,
  jaeger,
  lauscherin,
  magd,
  seherin,
  stille_pfote: stillePfote,
  werwolf,
  schaefer,
  waescherin,
  zimmermann,
  spinnerin,
  schuster,
  blumenmaedchen,
  tueftler,
  grossmutter,
  grossvater,
  baeckerin,
  fischerin,
  schneiderin,
  gaensehirtin,
  wirtin,
  schmied,
  mueller,
  spielmann,
  imker,
} satisfies Record<string, ImageMetadata>;

export type Figure = keyof typeof figures;
