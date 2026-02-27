const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const EVENTS_URL = 'https://pin.gsu.edu/events?categories=8776&perks=FreeFood';
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

async function clickLoadMoreUntilDone(page) {
    let clickCount = 0;
    let retries = 0;
    const MAX_RETRIES = 3;

    while (true) {
        // Scroll to the bottom so the "Load More" button is in viewport
        await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
        await new Promise(r => setTimeout(r, 1000));

        // Look for the "Load More" button by its container class
        const loadMoreBtn = await page.$('.outlinedButton button');
        if (!loadMoreBtn) {
            console.log(`No more "Load More" button found after ${clickCount} clicks.`);
            break;
        }

        // Check if the button is visible
        const isVisible = await loadMoreBtn.evaluate(el => {
            const rect = el.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0;
        });

        if (!isVisible) {
            console.log('Load More button is hidden. Done loading.');
            break;
        }

        const beforeCount = await page.$$eval('a[href^="/event/"]', els => els.length);
        console.log(`Clicking "Load More" (click #${clickCount + 1}, ${beforeCount} events so far)...`);

        // Scroll button into view and click via JS for reliability
        await loadMoreBtn.evaluate(el => {
            el.scrollIntoView({ behavior: 'instant', block: 'center' });
        });
        await new Promise(r => setTimeout(r, 500));
        await loadMoreBtn.evaluate(el => el.click());
        clickCount++;

        // Wait for new event cards to appear (longer timeout)
        try {
            await page.waitForFunction(
                (prev) => document.querySelectorAll('a[href^="/event/"]').length > prev,
                { timeout: 10000 },
                beforeCount
            );
            retries = 0; // reset on success
        } catch {
            retries++;
            console.log(`No new events detected after click #${clickCount} (attempt ${retries}/${MAX_RETRIES})...`);
            if (retries >= MAX_RETRIES) {
                console.log('Max retries reached. All events are visible.');
                break;
            }
            // Try again — the click may not have registered
            continue;
        }

        // Wait for rendering to settle
        await new Promise(r => setTimeout(r, 1500));
    }
    return clickCount;
}

function buildCSV(events) {
    if (!events.length) return '';

    const headers = Object.keys(events[0]);
    const rows = [headers.map(h => `"${h}"`).join(',')];

    for (const row of events) {
        const values = headers.map(h => {
            const val = row[h] !== undefined ? '' + row[h] : '';
            return `"${val.replace(/"/g, '""')}"`;
        });
        rows.push(values.join(','));
    }

    return rows.join('\n');
}

async function run() {
    console.log('Launching Chrome...');
    const browser = await puppeteer.launch({
        executablePath: CHROME_PATH,
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 900 });

    // Intercept API requests to enforce FreeFood filter on every Load More call
    await page.setRequestInterception(true);
    page.on('request', request => {
        const url = request.url();
        if (url.includes('/api/discovery/event/search') && !url.includes('facets') && !url.includes('haspast')) {
            const parsed = new URL(url);
            // Inject filters if missing
            if (!parsed.searchParams.has('benefitNames[0]')) {
                parsed.searchParams.set('benefitNames[0]', 'FreeFood');
                console.log('  [filter] Injected benefitNames=FreeFood into API call');
            }
            if (!parsed.searchParams.has('categoryIds[0]')) {
                parsed.searchParams.set('categoryIds[0]', '8776');
                console.log('  [filter] Injected categoryIds=8776 into API call');
            }
            request.continue({ url: parsed.toString() });
        } else {
            request.continue();
        }
    });

    console.log(`Navigating to ${EVENTS_URL}`);
    await page.goto(EVENTS_URL, { waitUntil: 'networkidle2', timeout: 30000 });

    // Wait for event cards to appear
    await page.waitForSelector('a[href^="/event/"]', { timeout: 15000 });
    console.log('Page loaded. Looking for Load More button...');

    // Click "Load More" until all events are loaded
    const clicks = await clickLoadMoreUntilDone(page);
    console.log(`Finished loading (${clicks} Load More clicks).`);

    // Scrape the events from the fully-loaded page
    const events = await page.evaluate(() => {
        const eventCards = Array.from(document.querySelectorAll('a[href^="/event/"]'));

        return eventCards.map(cardLink => {
            try {
                const href = cardLink.getAttribute('href');
                const id = 'evt-' + href.split('/').pop().split('?')[0];

                const titleEl = cardLink.querySelector('h3');
                const title = titleEl ? titleEl.textContent.trim() : 'Untitled Event';

                const imgDiv = cardLink.querySelector('div[role="img"]');
                let imageUrl = '';
                if (imgDiv) {
                    const style = imgDiv.getAttribute('style');
                    const match = style.match(/src="([^"]+)"/) || style.match(/url\("?([^"]+)"?\)/);
                    if (match) imageUrl = match[1];
                }

                const dateEl = cardLink.querySelector('div[aria-label^="happening on"]');
                let date = '';
                let time = '';
                if (dateEl) {
                    const ariaLabel = dateEl.getAttribute('aria-label');
                    const dateTimeStr = ariaLabel.replace('happening on ', '');
                    const parts = dateTimeStr.split(' at ');
                    if (parts.length >= 2) {
                        time = parts[1];
                        const currentYear = new Date().getFullYear();
                        const parsedDate = new Date(`${parts[0]}, ${currentYear}`);
                        if (!isNaN(parsedDate)) {
                            date = parsedDate.toISOString().split('T')[0];
                        } else {
                            date = parts[0];
                        }
                    } else {
                        date = dateTimeStr;
                    }
                }

                const locEl = cardLink.querySelector('div[aria-label^="located at"]');
                let location = 'TBD';
                if (locEl) {
                    location = locEl.getAttribute('aria-label').replace('located at ', '');
                }

                const hostEl = cardLink.querySelector('span[aria-label^="hosted by"]');
                let description = '';
                if (hostEl) {
                    description = hostEl.getAttribute('aria-label');
                }

                return { id, title, location, date, time, description, imageUrl };
            } catch (err) {
                return null;
            }
        }).filter(e => e !== null);
    });

    await browser.close();

    console.log(`\nScraped ${events.length} events total.`);

    if (events.length === 0) {
        console.log('No events found. Exiting.');
        return;
    }

    // Deduplicate by event ID
    const seen = new Set();
    const uniqueEvents = events.filter(e => {
        if (seen.has(e.id)) {
            return false;
        }
        seen.add(e.id);
        return true;
    });

    const dupeCount = events.length - uniqueEvents.length;
    if (dupeCount > 0) {
        console.log(`Removed ${dupeCount} duplicate(s). ${uniqueEvents.length} unique events remain.`);
    }

    // Print preview
    uniqueEvents.forEach((e, i) => {
        console.log(`  ${i + 1}. ${e.title} | ${e.date} ${e.time} | ${e.location}`);
    });

    // Save CSV
    const filename = `events_export_${new Date().toISOString().slice(0, 10)}.csv`;
    const csvPath = path.join(__dirname, filename);
    fs.writeFileSync(csvPath, buildCSV(uniqueEvents), 'utf-8');
    console.log(`\nCSV saved to: ${csvPath}`);

    // Save JS data file for the web app (works without a server)
    const jsPath = path.join(__dirname, 'events_data.js');
    fs.writeFileSync(jsPath, `const EVENTS_DATA = ${JSON.stringify(uniqueEvents, null, 2)};`, 'utf-8');
    console.log(`JS data saved to: ${jsPath}`);
}

run().catch(err => {
    console.error('Scraper failed:', err.message);
    process.exit(1);
});
