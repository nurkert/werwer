// The iPhone source under the name AltStore users know (lib/ios-source.ts).
import type { APIRoute } from 'astro';

import { iosSource } from '../lib/ios-source';

export const GET: APIRoute = ({ site }) => iosSource(site);
