import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'

const username = process.env.PLAYWRIGHT_DEVICE_USER!
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD!

test.describe('pihole', () => {
  test('admin dashboard renders after authelia login', async ({ page, baseURL }, testInfo) => {
    await loginViaAuthelia(page, baseURL!, username, password)

    await page.goto('/admin/')
    await expect(page).toHaveTitle(/Pi-hole/i, { timeout: 60_000 })
    await expect(page.locator('#gravity_size')).toBeVisible({ timeout: 60_000 })
    await shoot(page, testInfo, 'dashboard')
  })
})
