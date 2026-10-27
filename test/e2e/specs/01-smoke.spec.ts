import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

test('pihole', async ({ page }) => {
  test.setTimeout(900_000)

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

  await test.step('gravity-update', async () => {
    await openPage(page, 'gravity', page.locator('#gravityBtn'))
    await page.locator('#gravityBtn').click()
    await expect(page.locator('#alertSuccess')).toBeVisible({ timeout: 600_000 })
    await expect(page.locator('#output')).toContainText('Done.')
    await shoot(page, 'gravity-update')
  })

  await test.step('settings-system', async () => {
    await openPage(page, 'settings/system', page.locator('#sysinfo-hostname'))
    await shoot(page, 'settings-system')
  })

  await test.step('restart-dns', async () => {
    await page.locator('.settings-selector .toggle:has(#expert-settings)').click()
    await expect(page.locator('#expert-settings')).toBeChecked()
    await expect(page.locator('.confirm-restartdns')).toBeVisible()
    await expect(page.locator('.confirm-restartdns')).toBeEnabled()
    await page.locator('.confirm-restartdns').click()
    await page.locator('.modal-dialog .btn-danger').click()
    await expect(async () => {
      await page.reload()
      await expect(page.locator('#sysinfo-hostname')).toBeVisible({ timeout: 5_000 })
    }).toPass({ timeout: 120_000 })
    await shoot(page, 'restart-dns')
  })
})
