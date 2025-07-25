import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'KawaiiSec OS',
  tagline: 'Cute. Dangerous. UwU-powered Linux for hackers.',
  url: 'https://kawaiisec.os',
  baseUrl: '/',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'dhruvabisht', // Usually your GitHub org/user name.
  projectName: 'KawaiiSec-OS', // Usually your repo name.

  onBrokenLinks: 'ignore',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/dhruvabisht/KawaiiSec-OS/tree/main/kawaiisec-docs/',
        },
          blog: false, // Disable blog functionality
          theme: {
            customCss: './src/css/custom.css',
          },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    navbar: {
      title: 'KawaiiSec OS',
      logo: {
        alt: 'KawaiiSec Mascot',
        src: 'img/Kawaii.png',
      },
      items: [
        { to: '/docs', label: 'Docs', position: 'left' },
        { to: '/docs/setup', label: 'Download', position: 'left' },
        { to: '/docs/tools', label: 'Tools', position: 'left' },
        { to: '/docs/roadmap', label: 'Roadmap', position: 'left' },
        {
          href: 'https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso',
          label: 'Download ISO',
          position: 'right',
          className: 'download-button',
        },
        {
          href: 'https://github.com/dhruvabisht/KawaiiSec-OS',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            { label: 'Getting Started', to: '/docs' },
            { label: 'Installation Guide', to: '/docs/setup' },
            { label: 'Tools & Scripts', to: '/docs/tools' },
            { label: 'Roadmap', to: '/docs/roadmap' },
          ],
        },
        {
          title: 'Download',
          items: [
            {
              label: 'Latest ISO (v2025.07.25)',
              href: 'https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso',
            },
            {
              label: 'Verify Checksums',
              href: 'https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso.sha256',
            },
            {
              label: 'GitHub Releases',
              href: 'https://github.com/dhruvabisht/KawaiiSec-OS/releases',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Discord Server',
              href: 'https://discord.gg/kawaiisec',
            },
            {
              label: 'GitHub Repository',
              href: 'https://github.com/dhruvabisht/KawaiiSec-OS',
            },
            {
              label: 'Telegram Channel',
              href: 'https://t.me/KawaiiSecOS',
            },
            {
              label: 'Report Issues',
              href: 'https://github.com/dhruvabisht/KawaiiSec-OS/issues',
            },
          ],
        },
        {
          title: 'Support',
          items: [
            { label: 'Documentation', to: '/docs' },
            { label: 'Installation Help', to: '/docs/setup' },
            { label: 'Tool Documentation', to: '/docs/tools' },
            { label: 'Email Support', href: 'mailto:support@kawaiisec.os' },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} KawaiiSec OS. Built with love, shell scripts, and Docusaurus. 🌸`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
