import type { Article, ArticleCategory, CmsPage, CompatibilityRecord, ProjectionMode } from './types';

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

async function getJson<T>(path: string): Promise<T | null> {
  const res = await fetch(`${API_URL}${path}`, { cache: 'no-store' });
  if (res.status === 404) {
    return null;
  }
  if (!res.ok) {
    throw new Error(`Échec de la requête ${path} : ${res.status}`);
  }
  return res.json() as Promise<T>;
}

export function getPage(locale: string, slug: string): Promise<CmsPage | null> {
  return getJson<CmsPage>(`/cms/pages/${locale}/${slug}`);
}

export function listPages(locale = 'fr'): Promise<CmsPage[]> {
  return getJson<CmsPage[]>(`/cms/pages?locale=${locale}`).then((pages) => pages ?? []);
}

export function listArticles(locale = 'fr', category?: ArticleCategory): Promise<Article[]> {
  const query = category ? `?locale=${locale}&category=${category}` : `?locale=${locale}`;
  return getJson<Article[]>(`/cms/articles${query}`).then((articles) => articles ?? []);
}

export function getArticle(locale: string, slug: string): Promise<Article | null> {
  return getJson<Article>(`/cms/articles/${locale}/${slug}`);
}

export function listCompatibility(filters: {
  deviceModel?: string;
  accessoryModel?: string;
  mode?: ProjectionMode;
}): Promise<CompatibilityRecord[]> {
  const params = new URLSearchParams();
  if (filters.deviceModel) params.set('deviceModel', filters.deviceModel);
  if (filters.accessoryModel) params.set('accessoryModel', filters.accessoryModel);
  if (filters.mode) params.set('mode', filters.mode);
  const query = params.toString();
  return getJson<CompatibilityRecord[]>(`/compatibility${query ? `?${query}` : ''}`).then((records) => records ?? []);
}
