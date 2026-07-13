import { test, expect, Page } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

const username = process.env.PLAYWRIGHT_DEVICE_USER!
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD!
const baseURL = `https://${process.env.PLAYWRIGHT_APP_DOMAIN}`

test.describe.serial('pihole', () => {
  let page: Page

  test.beforeAll(async ({ browser }) => {
    page = await browser.newPage({ ignoreHTTPSErrors: true })
    await loginViaAuthelia(page, baseURL, username, password)
  })

  test.afterAll(async () => {
    await page.close()
  })

  test('dashboard', async ({}, testInfo) => {
    await page.goto('/admin/')
    await expect(page).toHaveTitle(/Pi-hole/i)
    await expect(page.locator('#total_queries')).toBeVisible()
    await expect(page.locator('#gravity_size')).toBeVisible()
    await shoot(page, testInfo, 'dashboard')
  })

  test('domains', async ({}, testInfo) => {
    await openPage(page, 'groups/domains')
    await page.locator('#new_domain').fill('test-deny.com')
    await page.locator('#add_deny').click()
    await expect(page.locator('#domainsTable')).toContainText('test-deny.com')
    await page.locator('#new_domain').fill('test-allow.com')
    await page.locator('#add_allow').click()
    await expect(page.locator('#domainsTable')).toContainText('test-allow.com')
    await shoot(page, testInfo, 'domains')
  })

  test('lists', async ({}, testInfo) => {
    await openPage(page, 'groups/lists')
    await page.locator('#new_address').fill('https://test-e2e.example/list.txt')
    await page.locator('#btnAddBlock').click()
    await expect(page.locator('#listsTable')).toContainText('test-e2e.example')
    await shoot(page, testInfo, 'lists')
  })

  test('settings-dns', async ({}, testInfo) => {
    await openPage(page, 'settings/dns')
    await expect(page.locator('#DNSupstreamsTable')).toBeVisible()
    await shoot(page, testInfo, 'settings-dns')
  })

  test('local-dns', async ({}, testInfo) => {
    await openPage(page, 'settings/dnsrecords')
    await page.locator('#Hdomain').fill('test-local.com')
    await page.locator('#Hip').fill('10.0.0.5')
    await page.locator('#btnAdd-host').click()
    await expect(page.locator('#hosts-Table')).toContainText('test-local.com')
    await shoot(page, testInfo, 'local-dns')
  })

  test('settings-system', async ({}, testInfo) => {
    await openPage(page, 'settings/system')
    await shoot(page, testInfo, 'settings-system')
  })
})
