import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openPage } from '../helpers/nav'

test('local dns record survives upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await expect(page.locator('#gravity_size')).not.toHaveText(/^-|^0$/)
  await shoot(page, 'dashboard-after-upgrade')
  await openPage(page, 'settings/dnsrecords', page.locator('#Hdomain'))
  await expect(page.locator('#hosts-Table')).toContainText('upgrade-local.example.com')
  await shoot(page, 'local-dns-after-upgrade')
})
