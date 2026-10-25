// Rewrites relative links inside docs/*.md so they work on the website:
// other docs become /docs/<slug>/, everything else points to the file on GitHub.
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = fileURLToPath(new URL('../../..', import.meta.url));
const docsRoot = path.join(repoRoot, 'docs');
const githubBlob = 'https://github.com/nurkert/whowolf/blob/main/';
const githubTree = 'https://github.com/nurkert/whowolf/tree/main/';

const slugOf = (relativeDocPath) =>
  relativeDocPath
    .replace(/\.md$/, '')
    .split(path.sep)
    .map((segment) => segment.toLowerCase())
    .join('/');

function rewrite(url, filePath) {
  if (!url || /^(?:[a-z]+:|#|\/)/i.test(url)) return url;
  const [target, hash] = url.split('#');
  const absolute = path.resolve(path.dirname(filePath), decodeURIComponent(target));
  const anchor = hash ? `#${hash}` : '';
  if (absolute.startsWith(docsRoot) && absolute.endsWith('.md')) {
    return `/docs/${slugOf(path.relative(docsRoot, absolute))}/${anchor}`;
  }
  const relative = path.relative(repoRoot, absolute).split(path.sep).join('/');
  if (relative.startsWith('..')) return url;
  return (target.endsWith('/') || !path.extname(relative) ? githubTree : githubBlob) + relative + anchor;
}

function walk(node, visit) {
  visit(node);
  if (node.children) for (const child of node.children) walk(child, visit);
}

export default function remarkRepoLinks() {
  return (tree, file) => {
    const filePath = file.path ?? file.history?.[0];
    if (!filePath || !filePath.startsWith(docsRoot)) return;
    walk(tree, (node) => {
      if (node.type === 'link' || node.type === 'definition') node.url = rewrite(node.url, filePath);
    });
  };
}
