import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

const domain = 'upgrade-local.example.com'

test('local dns record before upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await openPage(page, 'settings/dnsrecords', page.locator('#Hdomain'))
  const table = page.locator('#hosts-Table')
  await expect(table.locator('tbody tr').first()).toBeVisible()
  if (!(await table.textContent())?.includes(domain)) {
    await page.locator('#Hdomain').fill(domain)
    await page.locator('#Hip').fill('10.0.0.9')
    await page.locator('#btnAdd-host').click()
  }
  await expect(table).toContainText(domain)
  await shoot(page, 'local-dns-before-upgrade')
})
