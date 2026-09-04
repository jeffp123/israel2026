import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const entries = defineCollection({
	loader: glob({ pattern: '**/*.mdx', base: './src/content/entries' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			date: z.coerce.date(),
			location: z.string().optional(),
			dek: z.string().optional(),
			cover: image().optional(),
		}),
});

export const collections = { entries };
