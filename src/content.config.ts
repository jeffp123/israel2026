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
			// journal = text I wrote in Israel (with [bracketed] later additions);
			// recollection = written afterwards from memory;
			// family = written by someone else in the family (set `author`).
			kind: z.enum(['journal', 'recollection', 'family']).default('recollection'),
			// When a family entry was actually written/posted (its `date` is the day it describes).
			written: z.coerce.date().optional(),
			author: z.string().optional(),
			// Where a family entry was originally published, if anywhere (e.g. Substack).
			source: z.string().url().optional(),
			dek: z.string().optional(),
			cover: image().optional(),
			// CSS object-position for the hero crop (e.g. "top" for a portrait page photo).
			coverPosition: z.string().optional(),
		}),
});

export const collections = { entries };
