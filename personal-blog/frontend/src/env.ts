import { defineEnvVars } from '@sveltejs/kit/env';

export const variables = defineEnvVars({ BLOG_DB: { schema: (input) => input ?? '' } });
