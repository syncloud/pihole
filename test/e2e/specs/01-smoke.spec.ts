import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

test('pihole', async ({ page }) => {
  await test.step('dashboard', async () => {
    await loginViaAuthelia(page)
    await expect(page).toHaveTitle(/Pi-hole/i)
    await expect(page.locator('#gravity_size')).toBeVisible()
    await shoot(page, 'dashboard')
  })

  await test.step('domains', async () => {
    await openPage(page, 'groups/domains', page.locator('#new_domain'))
    await page.locator('#new_domain').fill('test-deny.com')
    await page.locator('#add_deny').click()
    await expect(page.locator('#domainsTable')).toContainText('test-deny.com')
    await page.locator('#new_domain').fill('test-allow.com')
    await page.locator('#add_allow').click()
    await expect(page.locator('#domainsTable')).toContainText('test-allow.com')
    await shoot(page, 'domains')
  })

  await test.step('lists', async () => {
    await openPage(page, 'groups/lists', page.locator('#new_address'))
    await page.locator('#new_address').fill('https://test-e2e.example/list.txt')
    await page.locator('#btnAddBlock').click()
    await expect(page.locator('#listsTable')).toContainText('test-e2e.example')
    await expect(page.locator('#listsTable')).toContainText('StevenBlack')
    await shoot(page, 'lists')
  })

  await test.step('settings-dns', async () => {
    await openPage(page, 'settings/dns', page.locator('#DNSupstreamsTable'))
    await shoot(page, 'settings-dns')
  })

  await test.step('local-dns', async () => {
    await openPage(page, 'settings/dnsrecords', page.locator('#Hdomain'))
    await page.locator('#Hdomain').fill('test-local.com')
    await page.locator('#Hip').fill('10.0.0.5')
    await page.locator('#btnAdd-host').click()
    await expect(page.locator('#hosts-Table')).toContainText('test-local.com')
    await shoot(page, 'local-dns')
  })

  await test.step('settings-system', async () => {
    await openPage(page, 'settings/system', page.locator('.content-header'))
    await shoot(page, 'settings-system')
  })
})
