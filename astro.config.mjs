// @ts-check

import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import { defineConfig, fontProviders } from 'astro/config';

// https://astro.build/config
export default defineConfig({
	site: 'https://jeffp123.github.io',
	base: '/israel2026',
	integrations: [mdx(), sitemap()],
	// photoswipe is loaded via a dynamic import(), so Vite only discovers it after the first
	// page load and re-optimizes mid-session, which 504s the import ("Outdated Optimize Dep")
	// and silently breaks the lightbox in `astro dev`. Pre-bundle everything up front.
	vite: {
		optimizeDeps: {
			include: ['photoswipe', 'photoswipe/lightbox', 'swiper', 'swiper/modules'],
		},
	},
	fonts: [
		{
			provider: fontProviders.local(),
			name: 'Atkinson',
			cssVariable: '--font-atkinson',
			fallbacks: ['sans-serif'],
			options: {
				variants: [
					{
						src: ['./src/assets/fonts/atkinson-regular.woff'],
						weight: 400,
						style: 'normal',
						display: 'swap',
					},
					{
						src: ['./src/assets/fonts/atkinson-bold.woff'],
						weight: 700,
						style: 'normal',
						display: 'swap',
					},
				],
			},
		},
	],
});
