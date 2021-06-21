/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'WALLABY Workflows',
  tagline: 'An AusSRC project',
  url: 'https://aussrc.github.io/',
  baseUrl: '/WALLABY_workflows/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'AusSRC',
  projectName: 'WALLABY_workflows',
  themeConfig: {
    navbar: {
      title: 'WALLABY Workflows',
      logo: {
        alt: 'WALLABY Workflows Logo',
        src: 'img/icon.jpg',
      },
      items: [
        {
          type: 'doc',
          docId: 'overview',
          position: 'left',
          label: 'Overview',
        },
        {
          type: 'doc',
          docId: 'getting_started',
          position: 'left',
          label: 'Getting started',
        },
        {
          type: 'doc',
          docId: 'configuration/end-to-end',
          position: 'left',
          label: 'Configuration',
        },
        {
          href: 'https://github.com/AusSRC/WALLABY_workflows',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Overview',
              to: '/docs/overview',
            },
            {
              label: 'Getting started',
              to: '/docs/getting_started',
            },
            {
              label: 'Configuration',
              to: '/docs/configuration/end-to-end',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Website',
              href: 'https://aussrc.org',
            },
            {
              label: 'WALLABY Survey',
              href: 'https://wallaby-survey.org/'
            }
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/AusSRC',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} AusSRC.`,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl:
            'https://github.com/AusSRC/WALLABY_workflows',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
