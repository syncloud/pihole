import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

const domain = 'upgrade-deny.example.com'

test('deny domain before upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await openPage(page, 'groups/domains', page.locator('#new_domain'))
  const table = page.locator('#domainsTable')
  await expect(table.locator('tbody tr').first()).toBeVisible()
  if (!(await table.textContent())?.includes(domain)) {
    await page.locator('#new_domain').fill(domain)
    await page.locator('#add_deny').click()
  }
  await expect(table).toContainText(domain)
  await shoot(page, 'domains-before-upgrade')
})
