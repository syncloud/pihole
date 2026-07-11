import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

test.describe('pihole', () => {
  test('admin dashboard loads and shows the gravity blocklist', async ({ page }, testInfo) => {
    await page.goto('/admin/')

    const gravity = page.locator('#gravity_size')
    await expect(gravity).toBeVisible({ timeout: 60_000 })
    await shoot(page, testInfo, 'dashboard')

    await expect(gravity).toHaveText(/^[\d,]+$/, { timeout: 60_000 })
    await expect(page.locator('#total_queries')).toBeVisible()
  })
})
