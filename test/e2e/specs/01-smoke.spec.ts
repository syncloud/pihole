import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

test.describe('pihole', () => {
  test('admin dashboard renders', async ({ page }, testInfo) => {
    await page.goto('/admin/')

    await expect(page).toHaveTitle(/Pi-hole/i, { timeout: 60_000 })
    await expect(page.locator('#gravity_size')).toBeVisible({ timeout: 60_000 })
    await shoot(page, testInfo, 'dashboard')
  })
})
