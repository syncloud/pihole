import type { Page } from '@playwright/test'
import * as fs from 'node:fs'
import * as path from 'node:path'
import { env } from './env'

const dir = env('PLAYWRIGHT_ARTIFACT_DIR')

export async function capture(page: Page, name: string): Promise<void> {
  fs.mkdirSync(dir, { recursive: true })
  await page.screenshot({ path: path.join(dir, `${name}.png`), fullPage: false })
}

export async function shoot(page: Page, name: string): Promise<void> {
  await page.waitForTimeout(500)
  await capture(page, name)
}
