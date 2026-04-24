import { defineConfig } from "@docmd/core";

export default defineConfig({
  title: 'GovBox PRO - Dokumentácia',
  url: 'https://pro.govbox.sk',

  // --- Branding ---
  logo: {
    light: 'assets/images/SD_icon.png',
    dark: 'assets/images/SD_icon.png',
    alt: 'Logo',
    href: '/',
  },
  favicon: 'assets/images/SD_icon.png',

  // --- Source & Output ---
  src: 'docs',
  out: 'dist',

  // --- Layout & UI Architecture ---
  layout: {
    spa: true,
    header: {
      enabled: true,
    },
    sidebar: {
      collapsible: true,
      defaultCollapsed: false,
    },
    optionsMenu: {
      position: 'header',
      components: {
        search: true,      
        themeSwitch: true, 
        sponsor: null,
      }
    },
    footer: {
      style: 'complete',
      description: 'Jednoduchá, intuitívna a rýchla schránka.',
      content: '© Služby Slovensko.Digital, s.r.o.',
      branding: false
    }
  },

  // --- Theme Settings ---
  theme: {
    name: 'default',        // Options: 'default', 'sky', 'ruby', 'retro'
    appearance: 'system',   // 'light', 'dark', or 'system'
    codeHighlight: true,
    customCss: [
      '/assets/css/branding.css' // Path relative to site root
    ]
  },

  // --- General Features ---
  minify: true,           
  autoTitleFromH1: true,  
  copyCode: true,         
  pageNavigation: true,   
  
  customJs: [],           

  // --- Navigation ---
  navigation: [
    { title: 'Úvod', path: '/', icon: 'home' },
    {
      title: 'Začíname',
      icon: 'rocket',
      children: [
        { title: 'Prihlásenie', path: '/getting-started/login' },
        { title: 'Správa schránok', path: '/getting-started/mailbox-management' },
        { title: 'Správa používateľov', path: '/getting-started/user-management' },
        { title: 'Správa skupín', path: '/getting-started/group-management' },
      ],
    },
    {
      title: 'Základné pojmy',
      icon: 'book',
      children: [
        { title: 'Prehľad', path: '/concepts/overview' },
        { title: 'Schránka', path: '/concepts/mailbox' },
        { title: 'Správa', path: '/concepts/message' },
        { title: 'Vlákno', path: '/concepts/thread' },
        { title: 'Štítok', path: '/concepts/label' },
        { title: 'Tenant', path: '/concepts/tenant' },
        { title: 'Používateľ', path: '/concepts/user' },
        { title: 'Skupina', path: '/concepts/group' },
        { title: 'Filter', path: '/concepts/filter' },
        { title: 'Notifikácia', path: '/concepts/notification' },
        { title: 'Pravidlo', path: '/concepts/rule' },
      ],
    },
    {
      title: 'Správy',
      icon: 'mail',
      children: [
        { title: 'Prevzatie správ', path: '/messages/receiving' },
        { title: 'Zobrazenie správ', path: '/messages/viewing-messages' },
        { title: 'Zobrazenie vlákna', path: '/messages/viewing-thread' },
        { title: 'Odpovedanie', path: '/messages/replying' },
        { title: 'Premenovanie vlákna', path: '/messages/renaming-thread' },
        { title: 'Vyhľadávanie', path: '/messages/searching' },
        { title: 'História komunikácie', path: '/messages/communication-history' },
        { title: 'Stiahnutie správy', path: '/messages/downloading' },
      ],
    },
    {
      title: 'Prílohy',
      icon: 'paperclip',
      children: [
        { title: 'Zobrazenie prílohy', path: '/attachments/viewing' },
        { title: 'Stiahnutie prílohy', path: '/attachments/downloading' },
      ],
    },
    {
      title: 'Podpisovanie',
      icon: 'pen',
      children: [
        { title: 'Podpis dokumentu', path: '/signing/sign-document' },
        { title: 'Vyžiadanie podpisu', path: '/signing/request-signature' },
        { title: 'Hromadné podpisovanie', path: '/signing/bulk-signing' },
      ],
    },
    {
      title: 'Filtre',
      icon: 'filter',
      children: [
        { title: 'Vytvorenie filtra', path: '/filters/creating' },
      ],
    },
    {
      title: 'Štítky',
      icon: 'tag',
      children: [
        { title: 'Vytvorenie štítka', path: '/labels/creating' },
        { title: 'Úprava štítkov', path: '/labels/editing' },
        { title: 'Prístup k štítkom', path: '/labels/access-control' },
      ],
    },
    {
      title: 'Pravidlá',
      icon: 'settings',
      children: [
        { title: 'Vytvorenie pravidla', path: '/rules/creating' },
      ],
    },
    {
      title: 'Notifikácie',
      icon: 'bell',
      children: [
        { title: 'Nastavenie notifikácií', path: '/notifications/setting-up' },
      ],
    },
  ],

  // --- Plugins ---
  plugins: {
    seo: {
      defaultDescription: 'GovBox PRO - Prehľadná a efektívna elektronická komunikácia s orgánmi verejnej moci.',
      openGraph: { defaultImage: '' },
      twitter: { cardType: 'summary_large_image' }
    },
    sitemap: { defaultChangefreq: 'weekly' },
    analytics: {},
    search: {},
    mermaid: {},
    llms: {}
  },
  
  // --- Edit Link ---
  editLink: {
    enabled: true,
    baseUrl: 'https://github.com/slovensko-digital/govbox-pro/edit/main/docs/docs',
    text: 'Upraviť túto stránku'
  }
});
