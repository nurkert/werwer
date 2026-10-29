// The same iPhone source under a neutral name, e.g. for SideStore (lib/ios-source.ts).
import type { APIRoute } from 'astro';

import { iosSource } from '../lib/ios-source';

export const GET: APIRoute = ({ site }) => iosSource(site);
