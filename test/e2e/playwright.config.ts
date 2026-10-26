import { defineConfig, devices } from '@playwright/test'

const appDomain = process.env.PLAYWRIGHT_APP_DOMAIN ?? 'pihole.buster.com'

export default defineConfig({
  testDir: './specs',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  timeout: 120_000,
  expect: { timeout: 30_000 },
  use: {
    baseURL: `https://${appDomain}`,
    ignoreHTTPSErrors: true,
  },
  projects: [
    {
      name: 'desktop',
      use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 960 } },
    },
  ],
})
