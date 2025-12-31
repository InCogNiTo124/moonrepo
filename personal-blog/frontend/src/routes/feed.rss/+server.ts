import { env } from '$env/dynamic/private';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ fetch }) => {
	const blog_db = env.BLOG_DB;
	const response = await fetch(`http://${blog_db}/feed.rss`);
	const xml = await response.text();

	return new Response(xml, {
		headers: {
			'Content-Type': 'application/rss+xml',
			'Cache-Control': 'max-age=0, s-maxage=3600'
		}
	});
};
