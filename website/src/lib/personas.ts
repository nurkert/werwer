// The twenty personas (game_core `Persona`, in enum order: woman, man, woman, …) and their
// role costumes from design/source/figures/roles/<file>_<role>.png.
import { figures } from './figures';

/** File names of the personas, in the order of `Persona` in game_core. */
export const personaFiles = [
  'magd',
  'dorfbewohner',
  'baeckerin',
  'schmied',
  'fischerin',
  'mueller',
  'schneiderin',
  'spielmann',
  'gaensehirtin',
  'imker',
  'wirtin',
  'schaefer',
  'waescherin',
  'zimmermann',
  'spinnerin',
  'schuster',
  'blumenmaedchen',
  'tueftler',
  'grossmutter',
  'grossvater',
] as const;
export type PersonaFile = (typeof personaFiles)[number];

/** The roles of the game; every one but the villager has its own costume. */
export const roles = ['villager', 'werewolf', 'seer', 'witch', 'hunter', 'cupid'] as const;
export type Role = (typeof roles)[number];
export type CostumeRole = Exclude<Role, 'villager'>;
export const costumeRoles = roles.filter((role): role is CostumeRole => role !== 'villager');

/** Who shows each role on the start page: every persona once, women and men mixed. */
export const roleCast: Record<Role, PersonaFile[]> = {
  villager: ['dorfbewohner', 'magd', 'grossvater', 'wirtin'],
  werewolf: ['baeckerin', 'schmied', 'grossmutter'],
  seer: ['spielmann', 'fischerin', 'tueftler'],
  witch: ['schneiderin', 'imker', 'blumenmaedchen'],
  hunter: ['gaensehirtin', 'mueller', 'schaefer'],
  cupid: ['zimmermann', 'spinnerin', 'schuster', 'waescherin'],
};

const costumes = import.meta.glob<{ default: ImageMetadata }>('../../../design/source/figures/roles/*.png', { eager: true });

/** A persona as the villager they look like, or in the costume of a role. */
export function personaFigure(file: PersonaFile, role: Role = 'villager'): ImageMetadata {
  if (role === 'villager') return figures[file];
  const costume = costumes[`../../../design/source/figures/roles/${file}_${role}.png`];
  if (!costume) throw new Error(`Missing costume figure: ${file}_${role}.png`);
  return costume.default;
}
