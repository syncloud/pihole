import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

test('deny domain survives upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await expect(page.locator('#gravity_size')).toBeVisible()
  await shoot(page, 'dashboard-after-upgrade')
  await openPage(page, 'groups/domains', page.locator('#new_domain'))
  await expect(page.locator('#domainsTable')).toContainText('upgrade-deny.example.com')
  await shoot(page, 'domains-after-upgrade')
})
